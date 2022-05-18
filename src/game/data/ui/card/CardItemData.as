package game.data.ui.card 
{
	import engine.ShellApi;
	
	import game.data.ConditionalData;
	import game.data.ParamList;
	import game.data.ads.CampaignData;
	import game.data.character.LookData;
	import game.data.display.AssetData;
	import game.data.text.TextData;
	import game.util.ClassUtils;
	import game.util.DataUtils;

	public class CardItemData
	{
		public function CardItemData( xml:XML = null, shellApi:ShellApi = null):void
		{
			if( xml != null )
			{
				parse(xml);
			}
			this.shellApi = shellApi;
		}
		
		private var shellApi:ShellApi;
		
		public var id:String;     		// unique id to identify card
		public var name:String;  		// name of item card, will appear at top of card (used for tracking campaign cards for ObjectCollected events)
		public var type:String;  		// type of item card.  Valid options are 'island', 'sponsor', 'promotion', or  'store'  
		public var subType:String;		// subfolder within type
		public var campaignId:String;
		public var membersOnly:Boolean;
		public var dontBitmap:Boolean;
		
		public var contentClass:Class;
		public var contentX:int;
		public var contentY:int;
		public var cardClassParams:ParamList;
		public var specialIds:Vector.<String>;
		public var looks:Vector.<LookData>;
		public var conditionals:Vector.<ConditionalData>;
		public var campaignData:CampaignData;
		public var value:*;
		
		public var assetsData:Vector.<AssetData> = new Vector.<AssetData>;
		public var buttonData:Vector.<CardButtonData> = new Vector.<CardButtonData>;
		public var radioButtonData:Vector.<CardRadioButtonData> = new Vector.<CardRadioButtonData>;
		public var textData:Vector.<TextData> = new Vector.<TextData>;
		public var yShift:Number = 0;
		
		/**
		 * Get look by id, can be Number or String, if id is not valid returns first look listed.
		 */
		public function getLook( id:* = null ):LookData
		{
			if( looks )
			{
				if( DataUtils.validString( id ))
				{
					for (var i:int = 0; i < looks.length; i++) 
					{
						if( looks[i].id == id )
						{
							return looks[i];
						}
					}
				}
				else if( id is Number && ( id < looks.length && id > -1 ) )
				{
					return looks[ int(id) ];
				}
				else	// if id is not valid return first look listed.
				{
					if( looks.length > 0 )
					{
						return looks[0];
					}
				}
			}
			return null;
		}
		
		
		public function getConditionalValue(id:String):*
		{
			if(conditionals != null)
			{	
				var conditionalData:ConditionalData
				for (var i:int = 0; i < conditionals.length; i++) 
				{
					conditionalData = conditionals[i];
					if(conditionalData.id == id)
						return conditionalData.value;
				}
			}
			return null;
		}
		
		
		public function parse( xml:XML ):void
		{
			// parse xml to cardData
			
			id = xml.attribute("id");
			if( xml.hasOwnProperty("name"))
			{
				name = DataUtils.getString( xml.name );
			}
			if( xml.hasOwnProperty("dontBitmap"))
			{
				dontBitmap = DataUtils.getBoolean( xml.dontBitmap );
			}
			if( xml.hasOwnProperty("type"))
			{
				type = DataUtils.getString( xml.type );
			}
			if( xml.hasOwnProperty("subType"))
			{
				subType = DataUtils.getString( xml.subType );
			}
			if( xml.hasOwnProperty("campaignID"))
			{
				campaignId = DataUtils.getString( xml.campaignID );
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
			
			if( xml.hasOwnProperty("buttons"))
			{
				var xButtons : XMLList = xml.buttons.btn;
				if( xButtons )
				{
					for(u = 0; u < xButtons.length(); u++)
					{
						buttonData.push( new CardButtonData(xButtons[u]) );
					}
				}
			}
			
			if ( xml.hasOwnProperty("radiobuttons"))
			{
				var xPos:Number;
				var yPos:Number; 
				
				if(xml.radiobuttons.hasOwnProperty("yShift"))
					yShift = DataUtils.getNumber(xml.radiobuttons.yShift);
				if(xml.radiobuttons.hasOwnProperty("y"))
					yPos = DataUtils.getNumber(xml.radiobuttons.y);
				if(xml.radiobuttons.hasOwnProperty("x"))
					xPos = DataUtils.getNumber(xml.radiobuttons.x);
				
				var xRadioButtons : XMLList = xml.radiobuttons.btn;
				if (xRadioButtons)
				{
					for (u = 0; u < xRadioButtons.length(); u++)
					{
						var newData:CardRadioButtonData = new CardRadioButtonData(xRadioButtons[u]);
						if(!isNaN(xPos)) newData.xPos = xPos;
						if(!isNaN(yPos)) newData.yPos = yPos;
						radioButtonData.push(newData);
					}
				}
			}
			
			if( xml.hasOwnProperty("textfields"))
			{
				var xTexts : XMLList = xml.textfields.text;
				if( xTexts )
				{
					for(u = 0; u < xTexts.length(); u++)
					{
						textData.push( new TextData(xTexts[u]));
					}
				}
			}
			
			if( xml.hasOwnProperty("contentClass"))
			{
				// Rick Hocker: className does not appear in xml - causes error
				// Mike H: the new format should be <contentClass><classname>
				// 		   so that we can add <x> or <y> nodes to position the content
				//		   right now it will support either
				var classString:String;
				
				if(xml.contentClass.hasOwnProperty("className"))
				{
					classString = DataUtils.getString( xml.contentClass.className );
				} else {
					classString = DataUtils.getString( xml.contentClass );
				}
				
				contentClass = ClassUtils.getClassByName( classString );
				
				if(xml.contentClass.hasOwnProperty("parameters"))
				{
					cardClassParams = new ParamList(XML(xml.contentClass.parameters));
				}
				
				// Add X and Y properties if they exist
				if (xml.contentClass.x)
				{
					contentX = xml.contentClass.x;
				}
				if (xml.contentClass.y)
				{
					contentY = xml.contentClass.y;
				}
			}
			
			if( xml.hasOwnProperty("specials"))
			{
				specialIds = new Vector.<String>();
				var xSpecials:XMLList = xml.specials.specialAbility;
				for(u = 0; u < xSpecials.length(); u++)
				{
					specialIds.push(DataUtils.getString(xSpecials[u]));
				}
			}
			
			if( xml.hasOwnProperty("looks"))
			{
				var xLooks : XMLList = xml.looks.look;
				if( xLooks )
				{
					if( !looks )
					{
						looks = new Vector.<LookData>();
					}
					for(u = 0; u < xLooks.length(); u++)
					{
						var lookData:LookData = new LookData( xLooks[u] );
						if( !DataUtils.validString( lookData.id ) )	// if id was not specified, using index as id
						{
							lookData.id =  String(u);
						}
						looks.push(lookData);
					}
				}
			}
			
			if( xml.hasOwnProperty("conditionals"))
			{
				var xConditionals : XMLList = xml.conditionals.conditional;
				if( xConditionals )
				{
					if( !conditionals )
					{
						conditionals = new Vector.<ConditionalData>;
					}
					for(u = 0; u < xConditionals.length(); u++)
					{
						var conditionalData:ConditionalData = new ConditionalData();
						conditionalData.parse( XML(xConditionals[u]) );
						conditionals.push(conditionalData);
					}
				}
			}
			
			if( xml.hasOwnProperty("value"))
			{
				if( XML(xml.value).hasOwnProperty( "conditional") )		// check for conditional
				{
					var conditionalId:String = DataUtils.getString(  XML(xml.value.conditional).attribute("id") );
					var conditional:ConditionalData;
					for (u = 0; u < conditionals.length; u++) 
					{
						if( conditionals[u].id == conditionalId )
						{
							value = conditionals[u];
							break;
						}
					}
				}
				else	// otherwise use value
				{
					value = DataUtils.getString( xml.value );
				}
			}
		}
	}
}