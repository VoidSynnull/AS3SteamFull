package game.data.ui.card 
{
	import ash.core.Entity;
	
	import game.data.ConditionalData;
	import game.data.ui.ButtonData;
	import game.util.DataUtils;
		
	public class CardButtonData extends ButtonData
	{
		
		public function CardButtonData( xml:XML = null ):void
		{
			super( xml );
		}
		
		protected override function parseXML( xml:XML ):void
		{
			super.parseXML( xml );
			
			if( !actions )
			{
				actions = new Vector.<CardAction>();
			}

			this.disabled = DataUtils.getBoolean( xml.attribute("disabled") );

			if( xml.hasOwnProperty("index") )
			{
				this.index = int( DataUtils.getNumber( xml.index ) );
			}
			
			if( xml.hasOwnProperty("actions") )
			{
				var xActions: XMLList = xml.actions.action;
				if( xActions )
				{
					for(var i : uint = 0; i < xActions.length(); i++)
					{
						actions.push( new CardAction( xActions[i]) );
					}
				}
			}
			
			if( xml.hasOwnProperty( "y" ))
			{
				y = DataUtils.getNumber( xml.y );	
			}
			
			if( xml.hasOwnProperty("conditional") )
			{
				conditional = new ConditionalData( XML(xml.conditional) );
			}
		}
		
		public var index:int = 0; 				// used by card to determine what 'row' the button shoudl be placed
		public var disabled:Boolean = false; 	// if true, no interactions will be applied
		public var actions:Vector.<CardAction>;
		public var conditional:ConditionalData;
		public var y:Number;
		
		public var hide:Boolean = false; 		// if true, clip visible is set to false
		public var entity:Entity;
	}
}