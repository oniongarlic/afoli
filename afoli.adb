with AWS.Client;
with AWS.Response;
with Ada.Command_Line;

with GNATCOLL.JSON; use GNATCOLL.JSON;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Float_Text_IO; use Ada.Float_Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO.Unbounded_IO; use Ada.Text_IO.Unbounded_IO;

with Ada.Calendar; use Ada.Calendar;
with Ada.Calendar.Formatting; use Ada.Calendar.Formatting;
with Ada.Calendar.Conversions; use Ada.Calendar.Conversions;

procedure AFoli is

 subtype GeoLatitude is Float range -180.0 .. 180.0;
 subtype GeoLongitude is Float range -180.0 .. 180.0;

 type LineDataRecord is record
  LineRef : Unbounded_String;
  OriginRef : Unbounded_String;
  DestinationRef : Unbounded_String;
  TimeDelay : Natural;
  Lat : Float range -90.0 .. 90.0;
  Lon : Float range -180.0 .. 180.0;
 end record;

 type StopTimeArray is array(Positive range <>) of LineDataRecord;

 type StopDataRecord is record
  Status : Unbounded_String;
  StopName : Unbounded_String;
  Arrivals : StopTimeArray(1 .. 50);
 end record;

 StopData  : StopDataRecord;

 procedure StopDataCB(Name : UTF8_String; Value : JSON_Value) is
 begin
  Put(Name);
  New_Line(1);  
 end StopDataCB;

 procedure PrintArrivalData(Value : JSON_Value) is
  Line : Unbounded_String;
  ArrivalTime : Natural;
  T : Ada.Calendar.Time;
 begin
  Line:=Value.Get("lineref");
  ArrivalTime:=Value.Get("expectedarrivaltime");

  Put(Line);
  Put(" ");

  T:=Ada.Calendar.Time_Of (Year => 1970, Month => 1, Day => 1) + Duration(ArrivalTime);

  Put(Ada.Calendar.Formatting.Image(T));

  New_Line(1);  
 end PrintArrivalData;

 procedure LoadData(StopName : String) is
  FoliData : JSON_Value := Create_Object;
  JSBody : Unbounded_String;
  Stop : JSON_Value := Create_Object;  
  Stops : JSON_Array;
 begin
  JSBody:=AWS.Response.Message_Body(AWS.Client.Get(URL => "http://data.foli.fi/siri/sm/" & StopName));
  FoliData:=Read(JSBody);
  StopData.Status:=FoliData.Get("status");

  if StopData.Status = "OK" then
   Stops := FoliData.Get("result");
   for I in 1 .. Length (Stops) loop
    Stop := Get(Stops, I);
    PrintArrivalData(Stop);
    -- Map_JSON_Object(Stop, StopDataCB'Access);
   end loop;
  else
    Put_Line("Stop data not available");
  end if;

 end LoadData;

begin
 if Ada.Command_Line.Argument_Count>0 then
   LoadData(Ada.Command_Line.Argument (1));
 else
   Put_Line("Stop ID argument required");
 end if;
end AFoli;
