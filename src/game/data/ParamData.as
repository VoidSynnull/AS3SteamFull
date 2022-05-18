package game.data
{
	import game.util.DataUtils;

	public class ParamData
	{
		public var id:String;
		public var value:*;
		public var type:String;
		
		public function ParamData( xml:XML = null)
		{
			if( xml != null )
			{
				this.parse( xml );
			}
		}

		public function parse( xml:XML ):void
		{
			this.id = DataUtils.getString( xml.attribute("id") );
			this.type = DataUtils.getString(xml.attribute("type"));
			this.value = xml;
		}
		
		public function clone():ParamData
		{
			var data:ParamData = new ParamData(null);
			data.id = this.id;
			data.type = this.type;
			data.value = this.value;
			
			return data;
		}
	}
}