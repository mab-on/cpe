module libcpe.client.scan;

import std.stdio;

import libcpe.core;

int app(string[] args)
{
  import std.getopt;

  string[] header_out;

  auto optRes = getopt(
    args,
    "header|o" , "" , &header_out,
  );

  if(optRes.helpWanted)
  {
    defaultGetoptPrinter("Usage" , optRes.options);
    return 0;
  }

  string[] responseHeader = send_ssdp_request();

  if( header_out.length )
  {
    foreach(field ; header_out)
    {
      writeln( responseHeader.http_header_value(field) );
    }
  }
  else {
    import std.array : join;
    writeln( responseHeader.join("\n") );
  }

  return 0;
}
