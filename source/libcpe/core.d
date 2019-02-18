module libcpe.core;

public import std.digest.md;
public import std.digest : toHexString;
import std.stdio; //remove after debuging
import std.json;

version(unittest)
{
  import std.stdio;
}

struct SecurityToken
{
	string user;
	string pwd;
	string auth;
	string realm;
	string nonce;

	bool complete()
	{
		return 
			user.length 
		&&	pwd.length 
		&&	auth.length 
		&&	realm.length 
		&&	nonce.length;
	}

	void unload()
	{
		user = user.init;
		pwd = pwd.init;
		auth = auth.init;
		realm = realm.init; 
		nonce = nonce.init;
	}

	bool wantsChallenge()
	{
		return 
			user.length 
		&&	pwd.length 
		&&	! realm.length
		&&	! auth.length
		&&	! nonce.length;
	}

	/**
	* Sets the state ready for .wantsChallenge
	* 
	* TODO: throw if user,pwd and realm are not set, because for .wantsChallenge to be true these attributes must be loaded
	*/
	void setWantsChallenge()
	{
		auth = auth.init;
		nonce = nonce.init;
		realm = realm.init;
	}
}

struct Location
{
  string scheme;
  string authority;
  string path = "/";

  this(string url)
  {
    this.set(url);
  }

	Location set(string url)
	{
		import std.string : indexOf;
    import std.socket : Address;

    size_t authority_start_idx = url.indexOf("://");
    if( -1 != authority_start_idx )
    {
      authority_start_idx += "://".length;
      this.scheme = url[0..authority_start_idx - "://".length ];
    }
    else {
      authority_start_idx = 0;
    }

    size_t path_begin_idx = url.indexOf( "/" , authority_start_idx );
    if( -1 != path_begin_idx )
    {
      this.authority = url[authority_start_idx..path_begin_idx];
      this.path = url[path_begin_idx..$];
    }
    else
    {
      this.authority = url[authority_start_idx..$];
    }

    return this;
	}

  @property string host()
  {
    import std.string : indexOf;

    if( -1 == this.authority.indexOf(':') )
    {
      return this.authority;
    }
    else
    {
      return this.authority[0..this.authority.indexOf(':')];
    }
  }

  @property ushort port()(ushort _default = 0)
  {
    import std.string : indexOf;
    import std.conv : to;

    if( -1 == this.authority.indexOf( ":" ) )
    {
      return _default;
    }
    else
    {
       return this.authority[1+this.authority.indexOf(':')..$].to!ushort;
    }
  }

  string toString()
  {
    return
      this.scheme ~ "://"
      ~ this.authority
      ~ this.path;
  }

}
unittest
{
  assert(Location("http://192.168.178.1:49000/tr64desc.xml").scheme == "http");
  assert(Location("http://192.168.178.1:49000/tr64desc.xml").authority == "192.168.178.1:49000");
  assert(Location("http://192.168.178.1:49000/tr64desc.xml").path == "/tr64desc.xml");
  assert(Location("http://192.168.178.1:49000/tr64desc.xml").host == "192.168.178.1");
  assert(Location("http://192.168.178.1:49000/tr64desc.xml").port == 49000);
}

string content_level_authentication_challenge(SecurityToken token)
{
  import std.format : format;
  import std.ascii : LetterCase;
  ubyte[16] secret =  (new MD5Digest()).digest( format("%s:%s:%s" , token.user , token.realm , token.pwd) ) ;
  return (new MD5Digest()).digest( format( "%s:%s" , toHexString!(LetterCase.lower)(secret) , token.nonce ) ).toHexString!(LetterCase.lower);

}
unittest
{	
  SecurityToken token;
  token.user = "admin";
  token.pwd = "gurkensalat";
  token.realm = "F!Box SOAP-Auth";
  token.nonce = "F758BE72FB999CEA";
  assert(content_level_authentication_challenge(token) == "b4f67585f22b0af7c4615db5a18faa14");
}


/**
* Broadcasts a simple service discovery request and wait to for response
*/
string[] send_ssdp_request()
{
  import std.datetime;
  import std.socket;
  string m_search =
          "M-SEARCH * HTTP/1.1\r\n"
          ~"MX: 10\r\n"
          ~"ST: urn:dslforum-org:device:InternetGatewayDevice:1\r\n"
          ~"HOST: 239.255.255.250:1900\r\n"
          ~"MAN: \"ssdp:discover\"\r\n"
          ~"\r\n";



  UdpSocket udp = new UdpSocket(AddressFamily.INET);

  Address from;
  size_t received;
  char[] receiveBuf;
  receiveBuf.length = 500;

  udp.setOption(SocketOptionLevel.SOCKET , SocketOption.RCVTIMEO , dur!"seconds"(5));
  udp.sendTo( m_search , new InternetAddress( "239.255.255.250",1900 ) );
  received = udp.receiveFrom( receiveBuf , SocketFlags.PEEK  , from );
  while(received == receiveBuf.length)
  {
    received = udp.receiveFrom( receiveBuf , SocketFlags.PEEK  , from );
  }

   return receiveBuf[0..received].http_header_byLine;
}



/**
* Loads scpd (service descriptor document) from the given location.
*/
string load_scpd(Location location)
{
  import std.conv : to;
  import std.socket;
  import std.uni : icmp;


  auto sock = new TcpSocket(new InternetAddress(location.host, location.port));
  scope(exit) sock.close();

  sock.send(
    "GET " ~ location.path ~ " HTTP/1.1\r\n"
    ~"HOST: "~ location.authority ~"\r\n"
    ~"CONNECTION: Close\"\r\n"
    ~"\r\n"
  );

  char[] content;
  char[] buf;
  buf.length = 1;

  while( sock.receive(buf) )
  {
    content ~= buf;
    if( content.length >= 4 && content[$-4..$] == "\r\n\r\n" )
    {
      break;
    }
  }
  string sLength = http_header_value(content.http_header_byLine , "content-length");
  if( sLength != "" )
  {
    buf.length = sLength.to!size_t;
  }
  size_t received = sock.receive(buf);

  while( received )
  {
    content ~= buf[0..received];
    received = sock.receive(buf);
    buf.length = received;
  }
  return content.to!string;
}


string[] http_header_byLine(T)(in T content_with_header)
{
  import std.algorithm.searching : countUntil;
  import std.array : split;
  import std.conv : to;
  return content_with_header[0..content_with_header.countUntil("\r\n\r\n")].to!string.split("\r\n");
}

string http_header_value(in string[] header , string field)
{
  import std.algorithm.searching : countUntil;
  import std.uni : sicmp;
  import std.string : strip;

  auto offset = header.countUntil!(a => 0 == sicmp(field~":" , a[0..1+field.length]));
  return offset == -1
  ? ""
  : header[ offset ][ 1+field.length..$ ].strip;
}

auto http_header_statusline(in string headerline)
{
  import std.conv;
  import std.regex;

  auto ctr = ctRegex!(`^([^\s]+)[\s]+([\d]+)[\s]+([^\s]+)`);
  auto hit = headerline.matchFirst(ctr);

  struct Statusline
  {
  	string http_version;
  	size_t status_code;
  	string reason_phrase;
  }
  auto result = Statusline();
  if(hit.length)
  {
  	result.http_version = hit[1] ;
	result.status_code = hit[2].to!size_t;
	result.reason_phrase = hit[3];
  }
  return result;
}

import std.uuid;
UUID parse_uuid(string uuid)
{
  import std.regex;

  auto capture = uuid.matchFirst(uuidRegex);
  if(capture.empty){ return UUID(); }

  return UUID(capture.hit);
}

struct MAC
{
  ubyte[6] data;

  this(UUID uuid)
  {
    this.data = uuid.data[10..$];
  }

  string toString()
  {
    import std.digest.digest;
    import std.algorithm : map;
    import std.array : join;
    import std.format;

    return format(
      "%x-%x-%x-%x-%x-%x",
      this.data[0],
      this.data[1],
      this.data[2],
      this.data[3],
      this.data[4],
      this.data[5]
    );
  }
}

unittest
{
  assert(MAC("739f75f0-a90c-4e42-ac13-2cc42d3c243e".parse_uuid()).toString() == "2c-c4-2d-3c-24-3e");
}


Argument[] call( Location cpe , Service service , Action action , SecurityToken token , ubyte _requests = 3)
{
  import std.algorithm.iteration : filter ;
  import std.conv : to;
  import std.socket;
  import std.uni : icmp;
  import libcpe.soaplike;
  import libdominator;
  
	Argument[] result;

	if( _requests <= 0 ) { return result; }

	auto actionElement = Element( action.name ).addAttribute(libcpe.soaplike.Attribute("xmlns:u", service.serviceType ));
	foreach( Argument arg ; action.argumentList.filter!(arg => arg.direction == "in") )
	{
		actionElement.addChild( Element(arg.name , arg.value) );
	}
  Message msg = Message();
  msg
    .body_
      .add( actionElement );

	if(token.complete)
	{
		msg.header	
		.add( 
			Element("ClientAuth")
			.addAttribute( libcpe.soaplike.Attribute( "xmlns:h", "http://soap-authentication.org/digest/2001/10/" ))
			.addAttribute( libcpe.soaplike.Attribute( "mustUnderstand", "1" ))
			.addChild( Element("Nonce" , token.nonce) )
			.addChild( Element("UserID" , token.user) )
			.addChild( Element("Auth" , token.auth) )
			.addChild( Element("Realm" , token.realm) )
		);
	}
  	else if(token.wantsChallenge)
  	{
		msg.header
	    .add( 
	    	Element("InitChallenge")
			.addAttribute( libcpe.soaplike.Attribute( "xmlns:h", "http://soap-authentication.org/digest/2001/10/" ))
			.addAttribute( libcpe.soaplike.Attribute( "mustUnderstand", "1" ))
			.addChild( Element("UserID" , token.user) )
	    );
  	}

	string request =
	"POST " ~ service.controlURL ~ " HTTP/1.1\r\n"
	~"HOST: "~ cpe.authority ~"\r\n"
	~"CONTENT-LENGTH: "~ msg.toString.length.to!string ~"\r\n"
	~"CONTENT-TYPE: text/xml; charset=\"utf-8\"\r\n"
	~"SOAPACTION: "~ service.serviceType ~ "#" ~ action.name ~ "\r\n"
	~"USER-AGENT: "~ "TODO" ~"\r\n"
	~"\r\n"
	~ msg.toString;
	
	char[] header;
  char[] buf;
  buf.length = 1;
  auto sock = new TcpSocket(new InternetAddress(cpe.host, cpe.port));
	scope(exit) sock.close();
	sock.send( request );
  while( sock.receive(buf) )
  {
    header ~= buf;
    if( header.length >= 4 && header[$-4..$] == "\r\n\r\n" )
    {
      break;
    }
  }
  size_t content_length = http_header_byLine(header).http_header_value("CONTENT-LENGTH").to!size_t;
  buf.length = content_length;
  sock.receive(buf);
	sock.close();

  if( 200 != header.http_header_byLine[0].http_header_statusline.status_code )
  {
		/**
		* If the token is complete and the received status code is not positive,
		* then we assume that our session has timed out and we need to refresh it
		*/
		if(token.complete)
		{
			 token.setWantsChallenge();
			 return call(cpe , service , action , token , --_requests);
		}
  }
	
	auto dom = new Dominator(buf.to!string);	
	foreach( Argument arg ; action.argumentList.filter!(arg => arg.direction == "out") )
  {
    foreach(Node node ; dom.filterDom(arg.name) )
    {
    	arg.value = dom.getInner(node);
      result ~= arg;
    }
  }

	if( 0 == result.length && token.wantsChallenge)
	{
		foreach(Node node ; dom.filterDom("Nonce") )
		{
		  token.nonce = dom.getInner(node);
		}

	  	foreach(Node node ; dom.filterDom("Realm") )
		{
		  token.realm = dom.getInner(node);
		}
		token.auth = content_level_authentication_challenge(token);
		return call(cpe , service , action , token , --_requests);
	}
  
  return result;
}

struct Action
{
  string name;
  Argument[] argumentList;
	
  JSONValue serialize()
  {
  	import std.algorithm : map;
		import std.array;
		
  	JSONValue result = JSONValue(["name":name]);
		result.object["argumentList"] = this.argumentList.map!( a => a.serialize() ).array;
  	
  	return result;
  }

  Action unserialize(JSONValue json)
  {
  	this.name = json["name"].str;
  	foreach(json_arg ; json["argumentList"].array)
  	{
			this.argumentList ~= Argument().unserialize(json_arg);
  	}
  	return this;
  }
}

struct Argument
{
  string name;
  string direction;
  string relatedStateVariable;
  string value;

  JSONValue serialize()
  {
  	return JSONValue([ 
  	"name": name,
  	"direction": direction,
  	"relatedStateVariable": relatedStateVariable,
  	"value": value
  	]);
  }

  Argument unserialize(JSONValue json)
  {
		this.name = json["name"].str;
		this.direction = json["direction"].str;
		this.relatedStateVariable = json["relatedStateVariable"].str;
		this.value = json["value"].str;
		return this;
  }
}

struct StateVariable
{
  string name;
  string dataType;
  string defaultValue;

  JSONValue serialize()
  {
  	return JSONValue([
  		"name":name,
  		"dataType":dataType,
  		"defaultValue":defaultValue
		]);
  }

  StateVariable unserialize(JSONValue json)
  {
		this.name = json["name"].str;
		this.dataType = json["dataType"].str;
		this.defaultValue = json["defaultValue"].str;
		return this;
  }
}

struct Service
{
  string serviceType;
  string serviceId;
  string controlURL;
  string eventSubURL;
  string SCPDURL;
  Action[] actionList;
  StateVariable[] serviceStateTable;

  Location scpd_location;

  JSONValue serialize()
  {
  	import std.algorithm : map;
		import std.array;
		
  	JSONValue result = JSONValue([
  		"serviceType":serviceType,
  		"serviceId":serviceId,
  		"controlURL":controlURL,
  		"eventSubURL":eventSubURL,
  		"SCPDURL":this.SCPDURL
		]);
		result.object["actionList"] = this.actionList.map!( a => a.serialize() ).array;
		result.object["serviceStateTable"] = this.serviceStateTable.map!( a => a.serialize() ).array;

  	return result;
  }

  Service unserialize(JSONValue json)
  {
  	this.serviceType = json["serviceType"].str;
  	this.serviceId = json["serviceId"].str;
  	this.controlURL = json["controlURL"].str;
  	this.eventSubURL = json["eventSubURL"].str;
  	this.SCPDURL = json["SCPDURL"].str;
  	foreach(json_action ; json["actionList"].array)
  	{
			this.actionList ~= Action().unserialize(json_action);
  	}
		foreach(json_variable ; json["serviceStateTable"].array)
  	{
			this.serviceStateTable ~= StateVariable().unserialize(json_variable);
  	}
		return this;
  }
}

Service[] load_services(Location device_desc_location)
{
  import libdominator;
  import std.uni : toLower;

  auto dom = new Dominator();
  Service[] serviceList;

  dom.load( load_scpd(device_desc_location) );

  /*
  * collect services
  */
  foreach( serivceNode ; dom.filterDom("service") )
  {
    Service service;
    service.scpd_location = device_desc_location;
    foreach( serviceItem ; serivceNode.getChildren() )
    {
      switch(serviceItem.getTag().toLower)
      {
        case "servicetype":
          service.serviceType = dom.getInner( serviceItem );
          break;

        case "serviceid":
          service.serviceId = dom.getInner( serviceItem );
          break;

        case "controlurl":
          service.controlURL = dom.getInner( serviceItem );
          break;

        case "eventsuburl":
          service.eventSubURL = dom.getInner( serviceItem );
          break;

        case "scpdurl":
          service.SCPDURL = dom.getInner( serviceItem );
          service.scpd_location.path = service.SCPDURL;
          break;

        default:
          break;
      }
    }
    serviceList ~= service;
  }
  return serviceList;
}

/**
* Collect actions for each service
*/
void load_service_actions(ref Service service)
{
  import libdominator;
  import std.uni : toLower;

  auto scpdDom = new Dominator( load_scpd( service.scpd_location ) );
  foreach( actionNode ; scpdDom.filterDom("action") )
  {
    Action action;
    foreach( actionItem ; actionNode.getChildren )
    {
      switch(actionItem.getTag().toLower)
      {
        case "name":
          action.name = scpdDom.getInner( actionItem );
          break;

        case "argumentlist":
          foreach( argumentListChild ; actionItem.getChildren )
          {
            if("argument" == argumentListChild.getTag().toLower)
            {
              Argument argument;
              foreach( argumentChild ; argumentListChild.getChildren )
              {
                switch(argumentChild.getTag().toLower)
                {
                  case "name":
                    argument.name = scpdDom.getInner( argumentChild );
                    break;

                  case "direction":
                    argument.direction = scpdDom.getInner( argumentChild );
                    break;

                  case "relatedstatevariable":
                    argument.relatedStateVariable = scpdDom.getInner( argumentChild );
                    break;

                  default:
                  break;
                }
              }
              action.argumentList ~= argument;
            }
          }
          break;

        default:
        break;
      }
    }
    service.actionList ~= action;
  }

  foreach( stateVariableNode ; scpdDom.filterDom("stateVariable") )
  {
    StateVariable variable;
    foreach( variableItem ; stateVariableNode.getChildren )
    {
      switch(variableItem.getTag().toLower)
      {
        case "name":
          variable.name = scpdDom.getInner( variableItem );
          break;

        case "datatype":
          variable.dataType = scpdDom.getInner( variableItem );
          break;

        case "defaultvalue":
          variable.defaultValue = scpdDom.getInner( variableItem );
          break;

        default: break;
      }
    }
    service.serviceStateTable ~= variable;
  }
}

string config_dir()
{
	import std.path : expandTilde;
	return expandTilde("~/.config/cpe-064/");
}