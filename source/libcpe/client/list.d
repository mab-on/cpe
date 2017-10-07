module libcpe.client.list;

import core.thread;
import std.algorithm : map , filter;
import std.array;
import std.path : baseName;
import std.getopt;
import std.stdio;
import std.json;
import libcpe.core;

int app(string[] args)
{

	import std.algorithm : canFind;
	import libcpe.client.core : printHelp , Opt_service_details;
	import libcpe.client.profile.core;

  bool 
  	list_services,
  	opt_no_args;

  string 
  	filter_service,
   	opt_cpe,
  	opt_profile,
  	filter_action;

	Opt_service_details[] opt_service_details;
	
  auto optRes = getopt(
    args,

    /*
    * either a profile has to be given or a CPE
    */
    "profile|p" , "A existing profile. See also 'cpe profile --help'" , &opt_profile,
    "cpe|c" , "URL of the service desctiption document from the CPE (Customer Premises Equipment). Can usually be found with 'cpe scan'." , &opt_cpe,
	
	/*
	* output filter options
	*/
    "services|q" , "If given, only services will be listed - actions will be ignored." , &list_services,
    "service|S" , "Filters services by serviceType" ,&filter_service,
    "service-details|s" , "" , &opt_service_details,
    "action|A" , "Filters actions by action name" , &filter_action,
    "no-args|n" , "Do not print action-arguments" , &opt_no_args
  );

  if( ! args.length || optRes.helpWanted )
  {
    printHelp("list" , optRes);
    return 1;
  }

	if( opt_cpe.length && opt_profile.length )
	{
		printHelp("list" , optRes);
    return 1;
	}

	if( ! opt_service_details.length)
	{
		opt_service_details = [ Opt_service_details.serviceType ];
	}
  
  Service[] serviceList;
  if( opt_profile.length )
  {
		auto file = known_profiles().filter!( f => f.baseName(".profile") == opt_profile );
		if(file.empty)
		{
			"no profile found".writeln();
			return 1;
		}
		serviceList = Profile().load(file.front()).services;
  }
  else
  {
		serviceList = load_services( Location(opt_cpe) );
  }
  
  foreach(ref Service service ; serviceList)
  {

    if( filter_service.length && !service.serviceType.canFind(filter_service) )
    { continue; }

		foreach( opt ; opt_service_details )
		{
			final switch(opt)
			{
				case Opt_service_details.serviceType:
					writeln("serviceType: " ~ service.serviceType);
					break;

				case Opt_service_details.serviceId:
					writeln("serviceId: " ~ service.serviceId);
					break;

				case Opt_service_details.controlURL:
					writeln("controlURL: " ~ service.controlURL);
					break;
					
				case Opt_service_details.eventSubURL:
					writeln("eventSubURL: " ~ service.eventSubURL);
					break;

				case Opt_service_details.SCPDURL:
					writeln("SCPDURL: " ~ service.SCPDURL);
					break;
			}
		}
    
    if( list_services ) { continue; }

	if(opt_cpe.length) { load_service_actions(service); }
	
    foreach(action ; service.actionList)
    {
    	if( filter_action.length && ! action.name.canFind(filter_action) ) { continue; }

      writeln('\t' , "Action: " , action.name );

			if( opt_no_args ) { continue; }

      if(action.argumentList.length)
      {
        writeln('\t' , '\t' , "Params:");
      }
      foreach(arg_i , argument ; action.argumentList)
      {
        write( '\t' , '\t', '\t');

        write(argument.direction, ' ');
        string argname;
        foreach(stateVariable ; service.serviceStateTable)
        {
          if(argument.relatedStateVariable == stateVariable.name)
          {
            write(stateVariable.dataType , ' ');
            argname = stateVariable.name;
            break;
          }
        }
        writeln( ( argname.length ? argname : argument.name ) );
      }
      writeln();
    }
  }
  
  return 0;
}
