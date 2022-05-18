package game.scenes.con2.shared.turnBased
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.group.Group;
	
	public class TurnBasedGroup extends Group
	{
		public function TurnBasedGroup(container:DisplayObjectContainer)
		{
			this.container = container;
			this.players = new Vector.<Entity>();
			this.index = 0;
			this.id = GROUP_ID;
		}
		
		public function start():void
		{
			
		}
		
		protected function nextTurn():void
		{
			
		}
		
		/**
		 * Function to override. Is called when turn(s) are over
		 */
		protected function result():void
		{
		}
		
		public function addPlayer(entity:Entity = null, id:String = ""):void
		{
			if(!entity)
				entity = new Entity();
			
			if(!entity.has(Id))
				entity.add(new Id(id));
			
			if(!entity.has(TurnBasePlayer))
			{
				var userControlled:Boolean = false;
				if(entity.get(Id).id == "player")
					userControlled = true;		
				entity.add(new TurnBasePlayer(userControlled));
			}
			
			parent.addEntity(entity);

			players.push(entity);
		}
		
		public function getPlayerById(id:String):Entity
		{
			for each(var entity:Entity in players)
			{
				if(entity.get(Id).id == id)
					return entity;
			}			
			
			return null;
		}
		
		protected var container:DisplayObjectContainer;
		protected var players:Vector.<Entity>;
		protected var currentPlayer:Entity;
		protected var index:uint;
		
		private const GROUP_ID:String = "turnBaseGroup";
	}
}