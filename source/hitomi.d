/**
 * ==================================================
 * 	hitomi.d
 * ==================================================
 * - LGPL v2
 * - zhanitest
 */
import std.stdio;
import std.string;
import std.json;
import std.net.curl;
import std.conv;
import std.regex;


/**
 *	청크
 */
struct DataChunk{
	string name;
	string language;
	string type;
	string[] parodies;
	string[] tags;
	string[] artists;
	string[] characters;
	uint id;
	string[] groups;
}


/**
 *	파일셋
 */
struct FileSet{
	uint id;
	string[] url;
}


/**
 *	꺼토미 히라
 */
class Hitomi{
	private:
	string base;
	
	/**
	 * 리퀘스트 래핑
	 */
	string req(string api, string base=""){
		string host = base=="" ? this.base:base;
		version(unittest){ writeln("Req>> "~host~api); } // 유닛테스트 할 때 요청할 URL 출력
		return to!string(get(host~api));
	}

	/**
	 * 생성자
	 */
	public:
	this(){
		this.base = "https://hitomi.la";
	}


	/**
	 * gallery.json 범위 값
	 */
	uint get_chunklength(){
		string api = "/searchlib.js";
		string html = req(api);
		
		// 패턴
		string rxp = r"gallery_jsons = ([\d]+);";

		auto rxr = match(html, rxp);
		return to!int(rxr.front()[1]);
	}


	/**
	 * 파일로 받아오고 JSON파싱 후 CHUNK로 저장
	 */
	DataChunk[] get_chunk(uint chunk_size){
		DataChunk[] big_chunk;

		// 유닛테스트 시에는 사이즈를 1로 줄임
		version(unittest){
			chunk_size = 1;
		}

		// 1 .. chunk_size 만큼 받아옴
		for(uint i=1; i<=chunk_size; i++){
			string j = to!string(i);
			
			// json포맷의 문자열

			// DataChunk로 변환
			auto json_array = parseJSON(
				req("/galleries"~j~".json")
			).array;

			// 하나씩 DataChunk로 변환
			foreach(e; json_array){
				DataChunk d;

				try{
					d.id = cast(uint)e["id"].integer;
					d.name = !("n" in e) || e["n"].isNull ?			null:e["n"].str;
					d.language = !("l" in e) || e["l"].isNull  ? 	null:e["l"].str;
					d.type = !("type" in e) || e["type"].isNull ? 	null:e["type"].str;
					d.parodies = !("p" in e) || e["p"].isNull ? 	null:cast(string[])e["p"].array;
					d.tags = !("t" in e) || e["t"].isNull ? 		null:cast(string[])e["t"].array;
					d.artists = !("a" in e) || e["a"].isNull ?		null:cast(string[])e["a"].array;
					d.characters = !("c" in e) || e["c"].isNull ? 	null:cast(string[])e["c"].array;
					d.groups = !("g" in e) || e["g"].isNull ? 		null:cast(string[])e["g"].array;
				}
				catch(JSONException x){
					writeln(e);
				}
				
				big_chunk ~= d;
			}
		}
		return big_chunk;
	}


	/**
	 * CHUNK에서 type을 읽어 비디오인 지 판단
	 */
	bool[] is_video(DataChunk[] chunks){
		bool[] result;

		foreach(c; chunks){
			result ~= (c.type=="anime") ? true:false;
		}

		return result;
	}


	/**
	 * ID로 읽어온 후 비디오인 지 판단
	 */
	bool[] is_video(uint[] ids){
		bool[] result;

		foreach(id; ids){
			string html = req("/galleries/"~to!string(id)~".html");	
			result ~= html.indexOf("/type/anime-all-1.html")>0 ? true:false;
		}

		return result;
	}


	/**
	 * URL 따기
	 */
	FileSet[] get_url(uint[] ids){
		FileSet[] result;
		bool[] iv = is_video(ids);

		for(uint i=0; i<ids.length; i++){
			FileSet fs;
			
			string id = to!string(ids[i]);
			bool v = iv[i];

			string api;
			string rxp;
			
			// 타입에 따라 요청해야할 주소와 패턴이 달라짐
			if(v){
				api = "/galleries/"~id~".html";
				rxp = r"streaming.hitomi.la.+";
			}
			else{
				api = "/reader/"~id~".html";
				rxp = r"g.hitomi.la.+<";
			}

			string html = req(api);
			auto rxr = matchAll(html, rxp); // empty 검사 필요

			// 타입에 따라 처리가 다름
			if(v){
				string url = to!string(rxr.front()); // 비디오 링크는 하나뿐임
				fs.id = ids[i];

				// 끄트머리에 ", ← 요거 지우기
				url = url[2..$-4].replace("\\u002d", "-");
				url = url.replace("\\", "");
				fs.url ~= "https://"~url;
			}
			else{
				fs.id = ids[i];
				foreach(r; rxr){
					string url = to!string(r.front());
					url = url.replace("g.hitomi.la", "ba.hitomi.la"); // URL 교정
					
					// 끄트머리에 < ← 요거 지우기
					fs.url ~= "https://"~(url[0..$-1]);
				}
			}
			result ~= fs;
		}
		return result;
	}


	/**
	 * URL 따기
	 */
	FileSet[] get_url(DataChunk[] chunks){
		uint[] id_list;
		foreach(c; chunks){
			id_list ~= c.id;
		}
		return(this.get_url(id_list));
	}
}


unittest{
	Hitomi client = new Hitomi();
	uint chunk_size = client.get_chunklength();
	assert(chunk_size > 0);

	
	// 좀 오래 걸리는 놈들
	// -----
	DataChunk[] chunks = client.get_chunk(chunk_size);
	assert(chunks.length > 0);

	bool[] iv = client.is_video(chunks);
	import std.algorithm.searching;
	assert(count(iv, true)  > 0);
	// -----


	// ***알림***
	// -개발자 취향이랑 전혀 관련 없음-
	// https://hitomi.la/galleries/1128227.html
	
	uint[] test_id = [987, 953]; // ID: 987 → 비디오임
	bool[] iv = client.is_video(test_id); 
	assert(iv[0], "비디오 구분 불가");

	FileSet[] fs = client.get_url(test_id); // ID: 987 → 비디오임
	assert(fs[0].url.length > 0);

	writeln();
	writeln(" -------------------- UNITTEST PASS --------------------");
}