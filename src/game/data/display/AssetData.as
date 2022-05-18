package game.data.display
{
	import game.data.ConditionalData;
	import game.util.DataUtils;

	public class AssetData
	{
		public var id : String;
		public var assetPath : String;
		public var effectData : EffectData;
		public var conditional:ConditionalData;

		public function AssetData(xml:XML = null ):void
		{
			if( xml )
			{
				parse(xml);
			}
		}

		public function parse( xml:XML ):void
		{
			this.id = DataUtils.getString( xml.attribute("id") );

			if( xml.hasOwnProperty( "assetPath" ) )
			{
				this.assetPath = DataUtils.getString(xml.assetPath);
			}
			if( xml.hasOwnProperty( "effect" ) )
			{
				this.effectData = new EffectData(XML(xml.effect));
			}
			if( xml.hasOwnProperty("conditional") )
			{
				this.conditional = new ConditionalData(XML(xml.conditional));
			}
		}

		public function duplicate():AssetData
		{
			var data:AssetData = new AssetData();
			data.id = id;
			data.assetPath = assetPath;
			data.effectData = effectData.duplicate();
			data.conditional = conditional.duplicate();
			return data;
		}
	}
}
