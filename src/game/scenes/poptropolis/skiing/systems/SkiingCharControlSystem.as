package game.scenes.poptropolis.skiing.systems
{
	import ash.core.Entity;
	import ash.core.System;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Scene;
	
	import game.components.entity.ZDepth;
	import game.scenes.poptropolis.common.StateString;
	import game.scenes.poptropolis.skiing.Skiing;
	
	import org.osflash.signals.Signal;
	
	public class SkiingCharControlSystem extends System
	{
		public var stoppedRunningAfterFinish:Signal;
		public var jumpComplete:Signal;
		public var _player:Entity
		private var _scene:Scene;
		private var mouseContainer:*;
		private var _shadow:Entity;
		private var _bForShadow:Number;
		private var _surfBoard:Entity
		private var _surfBoardSubmerged:Entity
		private var _surfBoardSplash:Entity
		
		public function SkiingCharControlSystem()
		{
			stoppedRunningAfterFinish = new Signal
			jumpComplete = new Signal
		}
		
		public function set bForShadow(value:Number):void
		{
			_bForShadow = value;
		}
		
		public function init ( __player:Entity, __scene:Scene, __shadow:Entity,__surfBoard:Entity,__surfBoardSubmerged:Entity,__surfBoardSplash:Entity):void{
			_scene = __scene
			_player = __player
			_shadow = __shadow
			_surfBoard = __surfBoard
			_surfBoardSubmerged = __surfBoardSubmerged
			_surfBoardSplash = __surfBoardSplash
		}
		
		override public function update( time : Number ) : void
		{
			var sp:Spatial
			var motion:Motion
			var char:Entity
			var st:StateString
			
			st = _player.get(StateString)
			sp = Spatial (_player.get(Spatial))
			motion = Motion (_player.get(Motion))
			
			var b:Number
			
			var zd:ZDepth = ZDepth(_player.get (ZDepth))
			
			switch (st.state) {
				case "skiing": 
				case "throughGate": 
				case "hit":
					b = 73 - Skiing.SLOPE_WIDTH * 447
					var minY:Number = Skiing.SLOPE_WIDTH * sp.x + b
					
					b = 330 - Skiing.SLOPE_WIDTH * 202
					var maxY:Number = Skiing.SLOPE_WIDTH * sp.x + b
					
					sp.y = Math.min (maxY, Math.max (sp.y,minY))
					
					zd.z = Skiing.calcZDepth (sp.x, sp.y + 30)
					//trace ("[SkiingCharControl] player z:" + zd.z) 
					
					break
				case "jumping":
					// eq = SkiUtils.getSlopeAndConst(_jumpPlayerX,_jumpPlayerY,934,361)
					//					 trace ("motion.vely:" + motion.velocity.y)
					var shadowSp:Spatial = Spatial(_shadow.get(Spatial))
					shadowSp.x = sp.x
					shadowSp.y = sp.x * Skiing.SLOPE_WIDTH + _bForShadow
					//trace ("motion.velocity.y:" + motion.velocity.y + "   " + Math.abs (shadowSp.y - sp.y))
					if (motion.velocity.y > 0 && sp.y > (shadowSp.y - 20) ) jumpComplete.dispatch()
					break;
			}
			_surfBoard.get(ZDepth).z = zd.z - 1
			_surfBoardSubmerged.get(ZDepth).z = zd.z - 2
			_surfBoardSplash.get(ZDepth).z = zd.z + 1
		}
	}
}