package game.scenes.poptropolis.longJump
{
	import ash.core.Entity;
	import ash.core.System;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.data.animation.entity.character.Fall;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.poptropolis.LongJumpAnim;
	import game.scenes.poptropolis.common.StateString;
	import game.util.CharUtils;
	
	import org.osflash.signals.Signal;
	
	public class LongJumpCharControlSystem extends System
	{
		public var _player:Entity
		
		public var jumpComplete:Signal;
		public var foul:Signal;
		
		public function LongJumpCharControlSystem()
		{
			jumpComplete = new Signal
			foul = new Signal
		}
		
		public function init (__player:Entity):void{
			_player = __player
		}
		
		override public function update( time : Number ) : void
		{
			var spatial:Spatial
			var motion:Motion
			
			spatial = Spatial (_player.get(Spatial))
			motion = Motion (_player.get(Motion))
			
		//	trace ("[LongJumpCharControl] x: "+ spatial.x + " motion.vel.y:" + motion.velocity.y + " accel:" + motion.acceleration.y + " sp.y:" + spatial.y)
			var st:String = _player.get (StateString).state 
			switch (st) {
				case "running": 
					if (spatial.x > LongJumpConstants.FOUL_LINE_X) {
						motion.acceleration.x = LongJumpConstants.ACCEL_X_AFTER_FOUL
						CharUtils.setAnim(_player,game.data.animation.entity.character.Grief)
						foul.dispatch()
					}
					break
				case "jumping":
					// goes below ground a bit
					if (spatial.y >  LongJumpConstants.GROUND_Y+30) {
						spatial.y = LongJumpConstants.GROUND_Y+30
						stopAndStand()
						CharUtils.setAnim(_player,game.data.animation.entity.character.Stand)
						trace ("[LongJumpCharControl] ---------------jump landed at player.x:" + spatial.x)
						jumpComplete.dispatch()
					}
					break
				case "jumpComplete":
					stopAndStand()
				case "foul":
					motion.acceleration.y = 0
					motion.velocity.y = 0
					if (motion.velocity.x <0) {
						trace ("[LongJumpCharControl] skid after jump done...")
						stopAndStand()
					}
					break
			}
		}
		
		private function stopAndStand():void {
			CharUtils.setAnim(_player,game.data.animation.entity.character.Stand)
			var motion:Motion = Motion (_player.get(Motion))
			motion.velocity.x = 0
			motion.velocity.y = 0
			motion.acceleration.x = 0
			motion.acceleration.y = 0
		}
		
		public function jump (char:Entity):void {
			var st:StateString = char.get (StateString)
			if (st.state == "running") {
				trace ("[LongJumpCharControl] jump!")
				CharUtils.setAnim(char,game.data.animation.entity.character.poptropolis.LongJumpAnim)
				var m:Motion = 	char.get (Motion) as Motion
				m.velocity.y = -400
				m.acceleration.y = 650
				st.state = "jumping"
			}
		}
		
		public function boost (char:Entity):void {
			var st:StateString = char.get (StateString)
			if (st.state == "jumping") {
				trace ("[LongJumpCharControl] boost!")
				CharUtils.setAnim(char,game.data.animation.entity.character.Fall)
				var m:Motion = char.get (Motion) as Motion
				m.velocity.y = -200
				//m.acceleration.y = -200
			}
		}
	}
}