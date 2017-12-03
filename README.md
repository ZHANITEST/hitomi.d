# hitomi.d
## NOTICE(알림)
hitomi.d didn't register on code.dlang.org.

so you should clone and add with 'local-add' command 👇 

```.shell
git clone https://github.com/zhanitest/hitomi.d
cd hitomi.d
dub add-local ./
```

and, add `"hitomi.d":"~master"` on your project 'dependencies' section.



## Document(문서)
```
git clone https://github.com/zhanitest/hitomi.d
cd hitomi.d
dub build --build=docs
cd docs

```



## Example(예제)
```.d
import std.stdio;
import hitomi;

void main()
{
	auto yap = new Hitomi();
	uint[] id = [444]; //gallery id's
	
	foreach(e; yap.get_url(id)){
		writeln(e.url); // get file urls
	}
}

```



## Donate(기부)
  - BTC: 12ooFjmj5cihS3DU1uj4qQDKpkqGAN8oU3
  - ETH: 0x405db2f70ffd6fa5b55245bac91e0020fbc6a9d4
  - XRP: rsG1sNifXJxGS2nDQ9zHyoe1S5APrtwpjV / 1000009096
👍 
