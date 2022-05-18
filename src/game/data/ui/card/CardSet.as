package game.data.ui.card
{
	public class CardSet
	{
		public var id:String;
		public var cardIds:Vector.<String>;
		
		public function CardSet( id:String, ...args )
		{
			this.id = id;
			
			cardIds = new Vector.<String>();
			for (var i:int = 0; i < args.length; i++) 
			{
				cardIds.push( String( args[i] ) );
			}
		}
		
		public function has( id:String ):Boolean
		{
			return ( cardIds.indexOf(id) != -1 );
		}
		
		public function add( id:String ):Boolean
		{
			if( !has( id ) )
			{
				cardIds.push( id );
				return true;
			}
			return false;
		}
		
		public function remove( id:String ):Boolean
		{
			var index:int = cardIds.indexOf(id);
			if (index > -1)
			{
				cardIds.splice(index, 1);
				return true;
			}
			return false;
		}
		
		public function reset():void
		{
			//cardIds.length = 0;
			cardIds = new Vector.<String>();
		}
		
		public function duplicate():CardSet
		{
			var cardSetClone:CardSet = new CardSet( this.id );
			cardSetClone.cardIds = this.cardIds.slice();
			return cardSetClone;
		}
	}
}