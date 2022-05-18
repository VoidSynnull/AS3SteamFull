package game.systems.actionChain.actions
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.components.entity.character.part.MetaPart;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.actionChain.ActionCommand;
	import game.util.CharUtils;
	
	public class SetAbilityActiveAction extends ActionCommand
	{
		public function SetAbilityActiveAction(char:Entity, partType:String, setActive:Boolean,resetActive:Boolean=false,time:Number=0)
		{
			_setActive = setActive;
			_entity = char;
			_part = CharUtils.getPart(char, partType);
			_resetActive = resetActive;
			_time = time;
			trace("---------------------------------" +_setActive);
			var metaPart:MetaPart = _part.get(MetaPart);
			if(metaPart)
			{
				if(metaPart.currentData.special.specialAbility)
				{
					metaPart.currentData.special.triggerable = _setActive;
					if(_resetActive)
					{
						var timer:Timer = new Timer(_time*1000, 0);
						timer.addEventListener(TimerEvent.TIMER, timerHandler);
						timer.start();
					}
					
				}
			}
			
		}
		
		private function timerHandler(event:TimerEvent):void {
			var metaPart:MetaPart = _part.get(MetaPart);
			if(metaPart)
			{
				if(metaPart.currentData.special.specialAbility)
				{
					metaPart.currentData.special.triggerable = !_setActive;
				}
			}
		}
		override public function preExecute(_pcallback:Function, group:Group, node:SpecialAbilityNode=null):void
		{
			
		}
		
		
		private var _setActive:Boolean;
		private var _resetActive:Boolean;
		private var _time:Number;
		private var _entity:Entity;
		private var _part:Entity;
	}
}


