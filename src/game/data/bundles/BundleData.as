package game.data.bundles
{

	import flash.display.DisplayObjectContainer;

	import game.components.ui.CardItem;
	import game.data.display.AssetData;
	import game.data.ui.card.CardSet;
	import game.util.DataUtils;

	/**
	 * BundleData stores data for bundle, what cards it includes, how it is displayed, etc.
	 * This is different from BundleDLCData, that only stores DLC relevant data and is stored gloablly.
	 * @author umckiba
	 */
	public class BundleData
	{
		// DLC aspects, these determined by bundles list in dlc
		private var _id:String = "";			// id of bundle
		public function get id():String { return _id; };
		private var _free:Boolean;			// flag for whether bundle is free or not
		public function get free():Boolean { return _free; };

		// Speciifc to bundle presentation
		public var title:String = "Bundle Title";
		public var index:int;
		public var cardSets:Vector.<CardSet>;	// CardSets contains list of card ids
		public var cardSetActive:CardSet;		// CardSets contains list of card ids
		public var cards:Vector.<CardItem>;		// list of CardItem for use with CardView
		public var bundleNum:int = 0;			// number icon displayed on bundle, if 0 none is displayed
		public var assetsData:Vector.<AssetData> = new Vector.<AssetData>;

		// TODO :: These aren't really data, would prefer if they aren't stored here in future
		public var isLoading:Boolean = false;
		public var clip:DisplayObjectContainer;

		public function BundleData()
		{
			cardSets = new Vector.<CardSet>();
		}

		public function clearAssets():void
		{
			clip = null;
			isLoading = false;
		}

		public function destroy():void
		{
			if( cards && cards.length > 0 )
			{
				for (var i:int = 0; i < cards.length; i++)
				{
					cards[i].manualDestroy();
				}
			}
			cards = null;
		}

		public function numCards():int
		{
			if( cards )
			{
				return cards.length
			}
			return 0;
		}

		public function applyDLCData( bundleDLCData:BundleDLCData ):void
		{
			_id = bundleDLCData.id;
			_free = bundleDLCData.free;
			//_active = bundleDLCData.active;	// Not used
			//_index = bundleDLCData.index;		// Not used
		}

		public function parse(xml:XML):void
		{
			// will parse xml, assigning values ot BundleData

			if( xml.hasOwnProperty("id") )
			{
				this.title = DataUtils.getString( xml.id );
			}

			if( xml.hasOwnProperty("name") )
			{
				this.title = DataUtils.getString( xml.name );
			}

			if( xml.hasOwnProperty("cardSets") )
			{
				if( xml.cardSets.hasOwnProperty("cardSet") )
				{
					var cardSets:XMLList = xml.cardSets.elements("cardSet") as XMLList;
					var cardSetXML:XML;
					var cards:XMLList;
					var cardSet:CardSet;

					var i:int;
					var j:int;
					for (i = 0; i < cardSets.length(); i++)
					{
						cardSetXML = cardSets[i] as XML;
						if( cardSetXML.hasOwnProperty("card") )
						{
							cardSet = new CardSet( DataUtils.getString(cardSetXML.attribute("id")) );
							cards = cardSetXML.elements("card") as XMLList;
							for (j = 0; j < cards.length(); j++)
							{
								cardSet.add( DataUtils.getString(cards[j]) )
							}
							this.cardSets.push( cardSet );
						}
					}
				}
			}

			if( xml.hasOwnProperty("bundleNum") )
			{
				this.bundleNum = int( DataUtils.getNumber( xml.bundleNum ) );
			}

			var u:uint;
			if( xml.hasOwnProperty("assets"))
			{
				var xAssets : XMLList = xml.assets.asset;
				if( xAssets )
				{
					for(u= 0; u < xAssets.length(); u++)
					{
						assetsData.push( new AssetData(xAssets[u]) );
					}
				}
			}
		}
	}
}


