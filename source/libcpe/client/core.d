module libcpe.client.core;
import std.getopt;

void printHelp( string app , GetoptResult optRes )
{
  import std.stdio;
  defaultGetoptPrinter( app~" [OPTIONS]" , optRes.options);
}

enum Opt_service_details
{
	serviceType,
	serviceId,
	controlURL,
	eventSubURL,
	SCPDURL
}

enum Opt_action_details
{
	name,
	argumentList
}

enum Opt_output_format
{
	human,
	json
}