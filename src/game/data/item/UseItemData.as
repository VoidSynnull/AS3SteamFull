package game.data.item
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.entity.Dialog;
	import game.components.motion.Destination;
	import game.components.scene.SceneInteraction;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;

	public class UseItemData
	{
		public var targetId:String;
		public var usedEvent:String;
		public var usedDialogId:String;
		public var dontUseDialogId:String;
		public var useFunction:Function;
		public var vicinity:Number;
		public var used:Boolean;
		public var defaultUseItemState:Boolean;
		
		public var minTargetDelta:Point;
		
		public function UseItemData(useFunction:Function, defaultUseItemState:Boolean = true, dontUseDialogId:String = null, usedEvent:String = null, usedDialogId:String = null, checkIfUsed:Boolean = true , targetId:String = null, vicinity:Number = NaN)
		{
			this.useFunction = useFunction;
			this.defaultUseItemState = defaultUseItemState;
			
			this.dontUseDialogId = dontUseDialogId;
			this.usedEvent = usedEvent;
			this.usedDialogId = usedDialogId;
			this.used = checkIfUsed;
			
			this.targetId = targetId;
			this.vicinity = vicinity;
			
			minTargetDelta = new Point(50,50);
		}
		
		public function useItem(group:Group):void
		{
			var shellApi:ShellApi = group.shellApi;
			var player:Entity = shellApi.player;
			var useItem:Boolean = defaultUseItemState;
			
			var target:Entity;
			
			if(targetId != null)
			{
				target = group.getEntityById(targetId);
				useItem = shouldUseItemOnEntity(player, target);
			}
			
			if(useItem)
			{
				if(usedEvent != null && usedDialogId != null)
				{
					if(group.shellApi.checkEvent(usedEvent) == used)
					{
						Dialog(player.get(Dialog)).sayById(usedDialogId);
						return;
					}
				}
				if(target != null)
				{
					moveToTarget(player, target);
				}
				else
				{
					useFunction();
				}
			}
			else
			{
				if(dontUseDialogId != null)
					Dialog(player.get(Dialog)).sayById(dontUseDialogId);
			}
		}
		
		private function moveToTarget(player:Entity, target:Entity):void
		{
			var interaction:SceneInteraction = target.get(SceneInteraction);
			if(interaction != null)
			{
				interaction.activated = true;
				interaction.validCharStates = new <String>[CharacterState.STAND];
				interaction.ignorePlatformTarget = true;
				interaction.reached.addOnce(useFunction);
				interaction.minTargetDelta = minTargetDelta
				return;
			}
			var targetSpatial:Spatial = target.get(Spatial);
			var destination:Destination = CharUtils.moveToTarget(player, targetSpatial.x, targetSpatial.y, false, reachedTarget, minTargetDelta);
			destination.validCharStates = new <String>[CharacterState.STAND];
			destination.ignorePlatformTarget = true;
		}
		
		private function reachedTarget(...args):void
		{
			useFunction();
		}
		
		private function shouldUseItemOnEntity(player:Entity, target:Entity):Boolean
		{
			if(target == null)
				return false;
			
			var targetSpatial:Spatial = target.get(Spatial);
			var pSpatial:Spatial = player.get(Spatial);
			var targetPos:Point = new Point(targetSpatial.x, targetSpatial.y);
			var playerPos:Point = new Point(pSpatial.x, pSpatial.y);
			var distance:Number = Point.distance(targetPos, playerPos);
			if(distance < vicinity || isNaN(vicinity))
				return true;
			return false;
		}
	}
}