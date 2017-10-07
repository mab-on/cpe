module libcpe.client.profile.add;

import std.getopt;
import libcpe.core;
import libcpe.client.core : printHelp;
import libcpe.client.profile.core;

version(unittest)
{
	import std.stdio;
}

int app(string[] args)
{
	string 
		cpe_addr,
	 	profile_name,
	 	user,
	 	password;

	auto optRes = getopt(
    args,
    "cpe" , "URL of the service desctiption document from the CPE (Customer Premises Equipment). Can usually be found with 'cpe scan'." , &cpe_addr,
    "name" , "Name of the profile to be added" , &profile_name,
    "user" , "The username used for communication with CPE" , &user,
    "password", "The users password" , &password
  );
	if (optRes.helpWanted)
  {
    printHelp("add" , optRes);
    return 1;
  }

	auto profile = Profile();
	profile.name = profile_name;
	profile.file = profile.hypotheticalFile();
	profile.cpe = Location(cpe_addr);
	profile.user = user;
	profile.password = password;
	profile.services = profile.cpe.load_services();
	foreach(ref srv ; profile.services) 
	{ 
		load_service_actions(srv); 
	}
	profile.save;
	return 0;
}