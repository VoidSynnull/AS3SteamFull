package game.data.profile
{

	public class TribeData
	{
		public var index:int;	// the specific index of the tribe, used with database and timelines
		public var id:String;		// text id for tribe, used for retrieving items
		public var name:String;	// The name of the tribe used for display & text read out
		public var jersey:String;
		
		private const JERSEY_PREFIX:String = "pg_jersey_";
		
		public function TribeData( index:int, id:String, name:String, jersey:String = "" ):void
		{
			this.index = index;
			this.id = id;
			this.name = name;
			this.jersey = ( jersey == "" ) ? JERSEY_PREFIX + id : JERSEY_PREFIX + jersey;
		}
		
		/*
		public function getJersey():String {
			return this.jersey;
		}
		*/

		public function toString():String {
			var s:String = '[TribeData index=' +  String(index);
			s += ' id=' + id;
			s += ' name=' + name;
			s += ' jersey=' + jersey;
			return s + ']';
		}
	}
}