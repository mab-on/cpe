module libcpe.client.profile.list;

import std.getopt;
import libcpe.client.core : printHelp;
import libcpe.client.profile.core;


int app(string[] args)
{
	bool 
		show_name,
		show_file,
		show_cpe,
		show_user,
		show_password;

	auto optRes = getopt(
    args,
    "name" , "Name of the profile" , &show_name,
    "file" , "The file, where profile informations are stored" , &show_file,
    "cpe" , "URL of the service desctiption document from the CPE (Customer Premises Equipment)" , &show_cpe,
    "user" , "CPE username" , &show_user,
    "password" , "The CPE users passowrd " , &show_password
  );
	if (optRes.helpWanted)
  {
    printHelp("list" , optRes);
    return 1;
  }

	if( !show_name && !show_file && !show_cpe && !show_user && !show_password)
	{
		show_name = true;
	}
	
	import std.stdio;
	import std.path : baseName;
	import std.string : stripRight;

	auto profile = Profile();
	foreach(file ; known_profiles())
	{
		if(show_cpe || show_user || show_password)
		{ profile.load(file); }

		(
			(show_name ? file.baseName(".profile")~'\t' : "")
			~(show_user ? profile.user~'\t' : "" )
			~(show_password ? profile.password~'\t' : "" )
			~(show_file ? file~'\t' : "")
			~(show_cpe ? profile.cpe.toString() : "" )
		).stripRight.writeln;
	}
	return 0;
}