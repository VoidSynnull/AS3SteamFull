package game.scenes.survival1.shared.systems
{	
	import ash.core.Engine;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import fl.motion.easing.Quadratic;
	
	import game.components.input.Input;
	import game.components.entity.collider.WaterCollider;
	import game.scenes.survival1.shared.components.ThermostatGaugeComponent;
	import game.scenes.survival1.shared.nodes.ThermostatNode;
	import game.systems.GameSystem;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.osflash.signals.Signal;
	
	public class ThermostatSystem extends GameSystem
	{
		private static const PING:String = "ping_13.mp3";
		private static const FREEZE:String = "freeze_01.mp3";
		private static const CAUGHT:String = "caught.mp3";
		private static const LOST:String = "mini_game_loss.mp3";
		
		private var input:Input;
		
		private var MAX_TEMP:Number = 100;
		private var MIN_TEMP:Number = 2;
		
		public var frozen:Signal;
		public var shiver:Signal;
		
		public function ThermostatSystem()
		{
			super( ThermostatNode, updateNode );
			frozen = new Signal();
			shiver = new Signal();
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			input = group.shellApi.inputEntity.get( Input );
			super.addToEngine( systemManager );
		}
		
		private function updateNode( node:ThermostatNode, time:Number ):void
		{	
			var collider:WaterCollider = node.collider;
			var gauge:ThermostatGaugeComponent = node.gauge;
			var motion:Motion = node.motion;
			var spatial:Spatial = node.spatial;
	
			if(( gauge.active && !input.lockInput && !gauge.frozen && motion.velocity.x == 0 && motion.velocity.y == 0 ) || ( gauge.freezingWater && collider.entered ))
			{
				gauge.coldCounter ++;
				
				if( gauge.coldCounter > gauge.coldTimer )
				{
					gauge.coldCounter = 0;
					
					if( gauge.freezingWater && gauge.alarmOff && !node.audio.isPlaying( SoundManager.EFFECTS_PATH + FREEZE ))
					{
						node.audio.play( SoundManager.EFFECTS_PATH + FREEZE );
					}
					
					if( gauge.temperature > MIN_TEMP )
					{
						gauge.temperature -= gauge.step;
						
						if( gauge.temperature < gauge.alertTemp ) 
						{
							if( gauge.alarmOff )
							{
								gauge.alarmOff = false;
								gauge.shakeMotion.active = true; 
								
								node.audio.play( SoundManager.EFFECTS_PATH + PING, true );
								
								if( !gauge.freezingWater )
								{
									shiver.dispatch();
								}
							}
							
							else
							{
								gauge.shakeDepth += .1;
								gauge.shakeMotion.shakeZone = new RectangleZone( -gauge.shakeDepth, -gauge.shakeDepth, gauge.shakeDepth, gauge.shakeDepth );
							}
						}
					}
					
					else
					{						
						frozen.dispatch();	
						
						if( group.shellApi.sceneName == "BeaverDen" && spatial.x > 1800 )
						{
							node.audio.play( SoundManager.EFFECTS_PATH + LOST );
						}
						
						else
						{
							node.audio.stop( SoundManager.EFFECTS_PATH + PING );
							node.audio.play( SoundManager.EFFECTS_PATH + FREEZE );
							node.audio.play( SoundManager.MUSIC_PATH + CAUGHT );
						}
						
						gauge.frozen = true;
						gauge.shakeMotion.active = false;
					}
				}
			}
			
			else if( !input.lockInput )
			{
				gauge.heatCounter ++;
				
				
				if( gauge.heatCounter > gauge.heatTimer )
				{
					gauge.heatCounter = 0;
					
					if( gauge.freezingWater )
					{
						node.audio.stop( SoundManager.EFFECTS_PATH + FREEZE );
					}
					
					if( gauge.temperature < MAX_TEMP )
					{
						gauge.temperature += gauge.step;
						
						if( !gauge.alarmOff )
						{
							if( gauge.temperature > gauge.alertTemp )
							{
								gauge.alarmOff = true;
								gauge.shakeMotion.active = false;
								
								node.audio.stop( SoundManager.EFFECTS_PATH + PING );
							}
							
							else
							{
								gauge.shakeDepth -= .1;
								gauge.shakeMotion.shakeZone = new RectangleZone( -gauge.shakeDepth, -gauge.shakeDepth, gauge.shakeDepth, gauge.shakeDepth );
							}
						}
					}
				}
			}
			
			gauge.redLiquidDisplayObject.alpha = gauge.temperature / 100;
			gauge.redOrbDisplayObject.alpha = gauge.temperature / 100;
			gauge.maskSpatial.scaleY = gauge.temperature / 100;
			
			if( gauge.freezingWater )
			{
				if( gauge.temperature < 100 )
				{
					gauge.thermostatTween.killAll();
					gauge.blueLiquidDisplayObject.alpha = 1;
					gauge.blueOrbDisplayObject.alpha = 1;
					gauge.hidden = false;
					gauge.tweening = false;
					gauge.thermostat.alpha = 1; //Tween.to( gauge.thermostat, 1, { alpha : 1, ease : Quadratic.easeOut });
				}
				
				else if( gauge.temperature > 99 && !gauge.hidden && !gauge.tweening )
				{
					gauge.tweening = true;
					gauge.blueLiquidDisplayObject.alpha = 0;
					gauge.blueOrbDisplayObject.alpha = 0;
					gauge.thermostatTween.to( gauge.thermostat, 1, { alpha : 0, ease : Quadratic.easeIn, onComplete : toggleHidden, onCompleteParams : [ node ]});
					
					if( node.audio.isPlaying( SoundManager.EFFECTS_PATH + FREEZE ))
					{
						node.audio.stop( SoundManager.EFFECTS_PATH + FREEZE );
					}
				}
			}
		}
		
		private function toggleHidden( node:ThermostatNode ):void
		{
			node.gauge.tweening = false;
			node.gauge.hidden = true;
		}
	}
}