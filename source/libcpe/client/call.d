module libcpe.client.call;

import std.stdio;
import libcpe.core;

int app(string[] args)
{
  import std.getopt;
  import std.file : exists;
  import libcpe.client.core : printHelp , Opt_output_format;
	import libcpe.client.profile.core;

  string
  	opt_profile,
  	opt_cpe,
  	opt_service,
  	opt_action,
		opt_user,
		opt_password;

  string[] opt_in;

  Opt_output_format opt_output;

  auto optRes = getopt(
    args,
		/*
    * either a profile has to be given or a CPE
    */
    "profile|p" , "A existing profile. See also 'cpe profile --help'" , &opt_profile,
    "cpe|c" , "URL of the service desctiption document from the CPE (Customer Premises Equipment). Can usually be found with 'cpe scan'." , &opt_cpe,

		"user" , "The username used for communication with CPE (overrides the profiles user)" , &opt_user,
    "password", "The users password (overrides the profiles password)" , &opt_password,

    "service|S" , "Specifies the service to be called" , &opt_service,
    "action|A" , "Specifies the Action to be called" , &opt_action,
    "in|i" , "Specifies the input argument for the given action" , &opt_in,

    "output|o" , "[human|json] Specifies the output format, human is default" , &opt_output
  );

  if(optRes.helpWanted)
  {
    printHelp("call" , optRes);
    return 0;
  }

  if( opt_cpe.length && opt_profile.length )
	{
		printHelp("call" , optRes);
    return 1;
	}

	Location cpe;
	SecurityToken token;
	Service[] serviceList;
	Profile profile;

	if(opt_cpe.length)
	{
		cpe.set(opt_cpe);
		serviceList = cpe.load_services();
		token.user = opt_user;
		token.pwd = opt_password;
	}
  else
  {
		profile.name = opt_profile;
		if( ! profile.hypotheticalFile().exists())
		{
			"no profile found".writeln();
			return 1;
		}
		profile.load(profile.hypotheticalFile());
		serviceList = profile.services;
		token.user = opt_user.length ? opt_user : profile.user;
		token.pwd = opt_password.length ? opt_password : profile.password;
		cpe = profile.cpe;
  }

  import std.algorithm.iteration : filter , splitter , map;
	import std.string : strip;
	
  foreach( Service service ; serviceList.filter!( s => s.serviceType == opt_service) )
  {
  	if( opt_cpe.length ) { service.load_service_actions(); }

    foreach( Action action ; service.actionList.filter!( a => a.name == opt_action ) )
    {
    	foreach( inArg ; opt_in)
    	{
				auto inArgGroup = inArg.splitter("=").map!(a => a.strip);
				foreach( ref Argument arg ; action.argumentList.filter!(arg => arg.direction == "in" && arg.relatedStateVariable == inArgGroup.front ) )
	      {
	      	inArgGroup.popFront;
					arg.value = inArgGroup.front;
	      }
    	}
      Argument[] result = cpe.call(service,action,token);
      final switch(opt_output)
			{
				case Opt_output_format.human:
					import std.algorithm.iteration : each;
					result.each!( 
						r => 
						writeln(
		        	"relatedStateVariable:" , '\t' , r.relatedStateVariable , '\n',
		        	"value:" , '\t' , r.value , '\n' ,
		        	"name:" , '\t' , r.name , '\n' ,
		        	"direction:" , '\t' , r.direction , '\n'
		      	)
					);
					break;

				case Opt_output_format.json:
					import std.array;
					import std.json;
					JSONValue([result.map!( a => a.serialize() ).array]).toString().writeln();
					break;
			}
    }
  }
  return 0;
}
