import std.stdio;


void printHelp() {
	writeln(
		"scan [OPTIONS]"
	);

	writeln(
		"list [OPTIONS]"
	);

	writeln(
		"call [OPTIONS]"
	);

	writeln(
		"profile [OPTIONS]"
	);
}



void main(string[] args)
{
	import std.algorithm.iteration : splitter;
	import scan = libcpe.client.scan;
	import list = libcpe.client.list;
	import call = libcpe.client.call;
	import profile = libcpe.client.profile.core;

	void dispatch(string[] appArgs)
	{
		switch(appArgs[0])
		{
			case "scan":
				scan.app(appArgs[0..$]);
				break;

			case "list":
				list.app(appArgs[0..$]);
				break;

			case "call":
				call.app(appArgs[0..$]);
				break;

			case "profile":
				profile.app(appArgs[0..$]);
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
	else if(args.length == 1)
	{
		string line;
		while ( (line = stdin.readln()) !is null )
		{
			dispatch(inAppArgs(line));
		}
	}
	else
	{
		printHelp(); return;
	}

}

string[] inAppArgs(string commandline)
{
	import std.conv : to;
	import std.string : stripRight;
	import std.uni : isWhite;

	string[] args;
	char terminator = 0x0;
	char[] arg;

	for(size_t i = 0 ; i < commandline.length ; i++ )
	{
		if(terminator == 0x0)
		{
			if(commandline[i].isWhite ) { continue; }

			if(commandline[i] == '\'' || commandline[i] == '"')
			{
				terminator = commandline[i];
			}
			else
			{
				terminator = ' ';
				arg ~= commandline[i];
			}
		}
		else if( terminator == commandline[i] && commandline[i-1] != '\\' )
		{
			args ~= arg.to!string;
			arg.length = 0;
			terminator = 0x0;
		}
		else
		{
			arg ~= commandline[i];
		}
	}

	if(arg.length)
	{
		args ~= arg.stripRight.to!string;
	}

	return args;
}