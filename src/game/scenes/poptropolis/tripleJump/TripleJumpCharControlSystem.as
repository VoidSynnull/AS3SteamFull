package game.scenes.poptropolis.tripleJump
{
	import ash.core.Entity;
	import ash.core.System;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.poptropolis.LongJumpAnim;
	import game.scenes.poptropolis.common.PoptropolisScene;
	import game.scenes.poptropolis.common.StateString;
	import game.util.CharUtils;
	
	import org.osflash.signals.Signal;
	
	public class TripleJumpCharControlSystem extends System
	{
		public var _player:Entity
		
		public var hopComplete:Signal;
		public var fallStarted:Signal;
		public var fallComplete:Signal;
		public var foul:Signal;
		public var holes:Array 
		
		private var _scene:PoptropolisScene;
		private var xVelocityMax:Number;
		private var _fixedVelX:Number;
		
		public function TripleJumpCharControlSystem()
		{
			hopComplete = new Signal
			fallStarted = new Signal
			fallComplete = new Signal
			foul = new Signal
		}
		
		public function init (__player:Entity,__scene:PoptropolisScene):void{
			_player = __player
			_scene = __scene
		}
		
		private function updateXVelocityMax():void {
		//	trace (".")
			var sp:Spatial = Spatial (_player.get(Spatial));
			// 1300 - 1480
			xVelocityMax = Math.max (600 + (sp.x - 1300)/180 * 300, 700)
		}
		
		override public function update( time : Number ) : void
		{
			var playerSp:Spatial
			var motion:Motion
			
			playerSp = Spatial (_player.get(Spatial))
			motion = Motion (_player.get(Motion))
			var pState:StateString = _player.get (StateString)
			
			//trace ("[TripleJumpCharControl] " + "state:" + pState.state + " x: "+ spatial.x + " motion.vel.y:" + motion.velocity.y + " accel:" + motion.acceleration.y + " sp.y:" + spatial.y)
			
			switch (pState.state) {
				
				case "running": 
					updateXVelocityMax()
					if (motion.velocity.x > xVelocityMax) {
						motion.velocity.x = xVelocityMax
					}
					if (checkOverHole()) {
						motion.acceleration.y = 600
						CharUtils.setAnim(_player,LongJumpAnim)
						pState.state = "falling"
						fallStarted.dispatch()
					}
					break
				case "runAfterHop":
					if (checkOverHole()) {
						motion.acceleration.y = 600
						CharUtils.setAnim(_player,LongJumpAnim)
						pState.state = "falling"
						fallStarted.dispatch()
					}
					motion.velocity.x = _fixedVelX
					break
				case "jumping":
					if (playerSp.y > TripleJump.GROUND_Y) {
						if (!checkOverHole()) {
							playerSp.y = TripleJump.GROUND_Y-8 // ????
							motion.acceleration.y = 0
							motion.velocity.y = 0
							hopComplete.dispatch()
						} else {
							pState.state = "falling"
							fallStarted.dispatch()
						}
					}
					motion.velocity.x = _fixedVelX
					break
				case "falling":
					if (playerSp.y > TripleJump.FALL_MAX_Y) {
						fallComplete.dispatch()
						trace ("[TripleJumpControlSystem] fall over!")
						pState.state = "fallComplete"
					}
					break
				case "jumpComplete":
					
				case "foul":
					motion.acceleration.y = 0
					motion.velocity.y = 0
					if (motion.velocity.x <0) {
						trace ("[TripleJumpCharControl] skid after jump done...")
						stopAndStand()
					}
					break
			}
			
			if ( TripleJump.DEBUG_SHOW_PLAYER_DOTS) {
				_scene.updateDebugTrackCharacter()
			}
		}
		
		private function checkOverHole ():Boolean {
			var inHole:Boolean = false
			var spatial:Spatial = Spatial (_player.get(Spatial))
			for each (var h:Array in holes){
				if (spatial.x > h[0] && spatial.x < h[1]) inHole = true
			}
			
			return inHole
		}
		
		private function stopAndStand():void {
			CharUtils.setAnim(_player,game.data.animation.entity.character.Stand)
			var motion:Motion = Motion (_player.get(Motion))
			motion.velocity.x = 0
			motion.acceleration.x = 0
		}
		
		public function jump (char:Entity, jumpNum:int = 1):void {
			var st:StateString = char.get (StateString)
			if (st.state == "running" || st.state == "runAfterHop" ) {
				var o:Object = TripleJump.JUMP_ACCELS[jumpNum]
				CharUtils.setAnim(char, LongJumpAnim)
				var m:Motion = 	char.get (Motion) as Motion
				m.velocity.y = o.velY 
				if (jumpNum == 2) {
					m.velocity.y -= (m.velocity.x - 700) * 200
					//m.velocity.x += (m.velocity.x - 700) * 200
				}
				m.acceleration.y = o.accelY
				_fixedVelX = m.velocity.x
				var sp:Spatial = char.get(Spatial)
				st.state = "jumping"
				trace ("[TripleJumpCharControl] ============================jump! VVVVVVVVVVVVVVVVVVEEEEL.x:" + m.velocity.x  + "  sp.x:" + sp.x  +     "  vel.y:" + m.velocity.y)
			}
		}
	}
}