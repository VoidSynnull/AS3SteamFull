package game.data.display
{
	import game.creators.data.EffectDataCreator;


	public class EffectData
	{
		public var filters:Array;

		public function EffectData( effectXML:XML = null ):void
		{
			filters = new Array();
			if( effectXML != null )
			{
				parse(effectXML);
			}
		}

		// TODO :: Need to add more error checking in this function, probably should move to a Util or Creator?
		public function parse( effectXML:XML ):void
		{
			var filter:* = EffectDataCreator.parseEffect( effectXML );
			if( filter != null )
			{
				this.filters.push( filter );
			}
		}

		public function duplicate():EffectData
		{
			var data:EffectData = new EffectData();
			data.filters = filters.concat();
			return data;
		}
	}
}
