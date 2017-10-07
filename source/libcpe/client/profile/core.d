module libcpe.client.profile.core;

import std.json;
import std.getopt;
import libcpe.core;


version(unittest)
{
	import std.stdio;
}

struct Profile
{
	string name;
	string file;
	Location cpe;
	Service[] services;
	string user;
	string password;

	JSONValue serialize()
	{
		import std.algorithm : map;
		import std.array;

		JSONValue result = JSONValue([
			"name": name,
			"file": file,
			"cpe": cpe.toString,
			"user": user,
			"password": password
		]);
		result.object["services"] = this.services.map!( a => a.serialize() ).array;
		return result;
	}

	
	Profile load(JSONValue json)
	{
		this.name = json["name"].str;
		this.cpe = Location(json["cpe"].str);
		this.user = json["user"].str;
		this.password = json["password"].str;
		foreach(json_srv ; json["services"].array)
		{
			this.services ~= Service().unserialize(json_srv);
		}
		return this;
	}

	Profile load(string file)
	{
		import std.file : readText;

		this.load(file.readText.parseJSON());
		this.file = file;
		return this;
	}

	string hypotheticalFile()
	{
		return config_dir() ~ name ~ ".profile";
	}
}

unittest
{
	import std.stdio;
	import std.json;

	auto profile = Profile();
	profile.name = "home";
	profile.cpe = Location("http://192.168.178.1:49000/tr64desc.xml");
	profile.services = load_services(profile.cpe);
	
	writeln( profile.serialize );
}

string[] known_profiles()
{
	import std.file;
	string[] profiles;
	if( ! config_dir.exists)
	{
		mkdirRecurse(config_dir);
	}
	
	foreach (string name; dirEntries(config_dir , "*.profile" , SpanMode.depth ))
	{
  		profiles ~= name;
	}
	return profiles;
}

void save(Profile profile)
{
	import std.file;
	import std.conv : to;

	if( ! config_dir.exists)
	{
		mkdirRecurse(config_dir);
	}
	std.file.write(config_dir ~ profile.name ~ ".profile" , profile.serialize.to!string);
}
unittest
{
	auto profile = Profile();
	profile.name = "_unittest";
	profile.user = "admin";
	profile.password = "gurkensalat";
	profile.file = profile.hypotheticalFile();
	profile.cpe = Location("http://192.168.178.1:49000/tr64desc.xml");
	profile.services = profile.cpe.load_services();
	foreach(ref srv ; profile.services)
	{
		load_service_actions(srv);
	}

	profile.save;
}

void printHelp()
{
  import std.stdio;
  writeln("add [OPTIONS]");
  writeln("list [OPTIONS]");
}

void app(string[] args)
{
	import add = libcpe.client.profile.add;
	import list = libcpe.client.profile.list;

	void dispatch(string[] appArgs)
	{
		switch(appArgs[0])
		{	
			case "add":
				add.app(appArgs[0..$]);
				break;
			
			case "list":
				list.app(appArgs[0..$]);
				break;

			default:
				printHelp();
				return;
		}
	}

	if(args.length >= 2)
	{
		dispatch(args[1..$]);
	}
	else
	{
		printHelp(); return;
	}
}