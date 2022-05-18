package game.scenes.con2.shared.cardGame
{
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import game.scenes.con2.shared.cardGame.systems.CardSlotSystem.CardSlot;

	public class CCGUser extends Component
	{
		public var cardCollection:CardCollection;
		public var deck:Vector.<Entity>;
		public var hand:Vector.<Entity>;
		public var currentSelection:Entity;
		public var dock:CardSlot;
		public var attack:CardSlot;
		public var bounty:CardSlot;
		public var score:CCGScore;
		public var id:String;
		private var _state:String;
		public var skip:Boolean;
		public var stolenFrom:Boolean;
		public var dockContext:Dictionary;
		public var attackContext:Dictionary;
		public var bountyContext:Dictionary;
		
		public function CCGUser(id:String = "player")
		{
			this.id = id;
			score = new CCGScore();
			cardCollection = new CardCollection();
			deck = new Vector.<Entity>();
			hand = new Vector.<Entity>();
			myTurn = false;
			skip = false;
			dockContext = new Dictionary();
			attackContext = new Dictionary();
			bountyContext = new Dictionary();
			dockContext[PICK] = "Choose\rCard";
			dockContext[PLACE] = "";
			dockContext[PLAY] = "Complete\rTurn";
			dockContext[WAIT] = "";
			
			attackContext[PICK] = "";
			attackContext[PLACE] = "Attack\rOpponent";
			attackContext[PLAY] = "Attack\rOpponent";
			attackContext[WAIT] = "";
			
			bountyContext[PICK] = "";
			bountyContext[PLACE] = "Collect\rGems";
			bountyContext[PLAY] = "Collect\rGems";
			bountyContext[WAIT] = "";
		}
		
		public function get myTurn():Boolean {return _state != WAIT;}
		
		public function set myTurn(turn:Boolean):void
		{
			if(turn)
				state = PICK;
			else
				state = WAIT;
		}
		
		public function get state():String{return _state;}
		
		public function set state(userState:String):void
		{
			_state = userState;
			if(dock != null && bounty != null && attack != null)
			{
				if(_state == PICK || _state == PLAY)
				{
					attack.highLight = false;
					bounty.highLight = false;
					dock.highLight = true;
				}
				else if(_state == PLACE)
				{
					attack.highLight = true;
					bounty.highLight = true;
					dock.highLight = false;
				}
				else
				{
					attack.highLight = false;
					bounty.highLight = false;
					dock.highLight = false;
				}
				if(dock.text != null)
				{
					dock.text.text = dockContext[_state];
					attack.text.text = attackContext[_state];
					bounty.text.text = bountyContext[_state];
				}
			}
		}
		
		public static const PICK:String = "pick";
		public static const PLACE:String = "place";
		public static const PLAY:String = "play";
		public static const WAIT:String = "wait";
	}
}