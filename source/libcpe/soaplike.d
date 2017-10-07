module libcpe.soaplike;

private static string soap_wrap_top = `<?xml version="1.0"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">`;
private static string soap_wrap_bottom = `</s:Envelope>`;

struct Message
{
  Body body_;
  Header header;

  string toString()
  {
    return .soap_wrap_top
          ~ this.header.toString()
          ~ this.body_.toString()
          ~ .soap_wrap_bottom;
  }
}

struct Body
{
  Element[] elements;
  Body add(Element element)
  {
    this.elements ~= element;
    return this;
  }

  string toString()
  {
    import std.algorithm : map , joiner;
    import std.conv : to;
    return "<s:Body>" ~ this.elements.map!( e => e.toString() ).joiner().to!string ~ "</s:Body>";
  }
}

struct Header
{
  Element[] elements;
  Header add(Element element)
  {
    this.elements ~= element;
    return this;
  }

  string toString()
  {
    import std.algorithm : map , joiner;
    import std.conv : to;
    return "<s:Header>" ~ this.elements.map!( e => e.toString() ).joiner().to!string ~ "</s:Header>";
  }
}

struct Attribute
{
  string name;
  string value;
  string prefix;

  this(string name  , string value)
  {
    import std.array : split;
    auto arr  =name.split(":");
    if( arr.length == 2 && arr[0] == "xmlns" )
    {
      this.name = arr[0];
      this.prefix = arr[1];
    }
    else
    {
      this.name = name;
    }

    this.value = value;
  }

  bool definesNamespace()
  {
    return this.prefix.length ? true : false;
  }

  string toString()
  {
    return (this.definesNamespace ? name ~ ":" ~ prefix : name) ~ `="` ~ value ~ `"`;
  }
}

struct Element
{
  string name;
  string value;
  Attribute[] attributes;
  string prefix;
  Element[] children;

  Element addAttribute(Attribute attribute)
  {
    this.attributes ~= attribute;
    if(attribute.definesNamespace)
    {
      this.prefix = attribute.prefix;
    }
    return this;
  }

  Element addChild( Element elem )
  {
    this.children ~= elem;
    return this;
  }

  string toString()
  {
    import std.conv : to;
    import std.algorithm : map;
    string str = "<" ~ (this.prefix.length ? this.prefix ~ ":" ~ this.name : this.name) ~ " ";

    foreach(attribute ; this.attributes)
    {
      str ~= " " ~ ( attribute.definesNamespace ? attribute.toString : this.prefix ~ ":" ~ attribute.toString ) ;
    }

    str ~= ">" ~ this.value;
    foreach( child ; this.children )
    {
      str ~= child.toString();
    }
    str ~= "</" ~ (this.prefix.length ? this.prefix ~ ":" ~ this.name : this.name)~ ">" ;
    return str;
  }
}