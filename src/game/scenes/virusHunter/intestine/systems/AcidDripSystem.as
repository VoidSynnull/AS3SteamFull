package game.scenes.virusHunter.intestine.systems 
{
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.intestine.components.AcidDrip;
	import game.scenes.virusHunter.intestine.nodes.AcidDripNode;
	import game.util.Utils;

	public class AcidDripSystem extends ListIteratingSystem
	{
		private var scene:Scene;
		
		public function AcidDripSystem(scene:Scene) 
		{
			super( AcidDripNode, updateNode );
			
			this.scene = scene;
		}
		
		private function updateNode( node:AcidDripNode, time:Number ):void
		{
			var drip:AcidDrip = node.acidDrip;
			var sack:Entity = node.entity;
			var acid:Entity = drip.acid;
			
			switch(drip.state)
			{
				case AcidDrip.IDLE_STATE:
					if(sack.get(Sleep).sleeping) return;
					
					drip.elapsedTime += time;
					if(drip.elapsedTime >= drip.waitTime)
					{
						Timeline(sack.get(Timeline)).gotoAndPlay("begin");
						Timeline(sack.get(Timeline)).handleLabel("drip", Command.create(handleDrip, node));
						
						drip.state = AcidDrip.DRIPPING_STATE;
					}
				break;
				
				case AcidDrip.DRIPPING_STATE:
					//Placeholder state. The state gets changed once the
					//drip animation has reached a certain frame.
				break;
				
				case AcidDrip.FALLING_STATE:
					acid.get(Spatial).y += (500 * time);
					
					if(acid.get(Spatial).y >= drip.endY)
					{
						var sound:String = "acid_splash_0" + Utils.randInRange(1, 3) + ".mp3";
						var audio:Audio = acid.get(Audio);
						
						if(audio == null)
						{
							audio = new Audio();
							
							acid.add(audio);
						}
						
						audio.play(SoundManager.EFFECTS_PATH + sound, false, SoundModifier.POSITION);
						
						drip.elapsedTime = 0;
						drip.waitTime = Utils.randNumInRange(0.25, 1);
						drip.emitter.get(Emitter).start = true;
						acid.get(Display).visible = false;
						
						drip.state = AcidDrip.IDLE_STATE;
					}
				break;
			}
		}
		
		private function handleDrip(node:AcidDripNode):void
		{
			node.audio.play(SoundManager.EFFECTS_PATH + "drip_0" + Utils.randInRange(1, 4) + ".mp3", false, SoundModifier.POSITION);
			
			node.acidDrip.acid.get(Spatial).y = node.acidDrip.startY;
			node.acidDrip.acid.get(Display).visible = true;
			
			node.acidDrip.state = AcidDrip.FALLING_STATE;
		}
	}
}