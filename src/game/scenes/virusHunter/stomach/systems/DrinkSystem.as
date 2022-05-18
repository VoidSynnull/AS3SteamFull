package game.scenes.virusHunter.stomach.systems
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	import ash.core.System;
	
	import engine.components.Audio;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.hit.Mover;
	import game.data.TimedEvent;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.stomach.Stomach;
	import game.util.SceneUtil;
	import game.util.Utils;

	public class DrinkSystem extends System
	{
		public static const IDLE_STATE:String		= "idle_state";
		public static const DRINKING_STATE:String	= "drinking_state";
		public static const DIGESTING_STATE:String	= "digesting_state";
		
		private static const MIN_WAIT_TIME:uint			= 2;
		private static const MAX_WAIT_TIME:uint			= 6;
		private static const ACID_HEIGHT:uint 			= 1340;
		
		private var state:String;
		private var elapsedTime:Number;
		
		private var scene:Stomach;
		private var events:VirusHunterEvents;
		private var drink:Emitter;
		private var acid:Emitter;
		
		private var isDrinking:Boolean = false;
		
		public function DrinkSystem(scene:Stomach, events:VirusHunterEvents, acid:Entity, drink:Entity)
		{
			this.state = DrinkSystem.IDLE_STATE;
			this.elapsedTime = 0;
			
			this.scene = scene;
			this.events = events;
			this.acid = acid.get(Emitter);
			this.drink = drink.get(Emitter);
		}
		
		override public function update(time:Number):void
		{
			var mover:Mover;
			var timeline:Timeline;
			var audio:Audio;
			
			if(isDrinking)
			{
				if(Math.random() < 0.2)
				{
					audio = this.group.getEntityById("acidSound").get(Audio);
					var sound:String = "acid_splash_0" + Utils.randInRange(1, 3) + ".mp3";
					audio.play(SoundManager.EFFECTS_PATH + sound, false, SoundModifier.POSITION);
				}
			}
			
			switch(this.state)
			{
				case IDLE_STATE:
					if(updateState(time, 5, DRINKING_STATE))
					{
						drink.start = true;
						drink.emitter.counter.resume();
						
						//Open Mouth muscle and remove Radial hit.
						if(this.group.shellApi.checkEvent(this.events.SPLINTER_REMOVED))
						{
							timeline = this.scene.mouth.get(Timeline);
							timeline.gotoAndPlay("open");
							timeline.reverse = false;
							timeline.handleLabel("close", Command.create(handleLabel, timeline, "close"));
							
							audio = this.scene.mouth.get(Audio);
							audio.play(SoundManager.EFFECTS_PATH + "contract_expand_muscle_0" + Utils.randInRange(1, 2) + ".mp3", false, SoundModifier.POSITION);
							
							this.group.getEntityById("muscle1").remove(Mover);
							this.group.getEntityById("doorMouth").add(new Sleep(false, true));
						}
					}
					break;
				case DRINKING_STATE:
					SceneUtil.addTimedEvent(this.group, new TimedEvent(2.3, 1, startDrinking));
					
					if(updateState(time, 10, DIGESTING_STATE))
					{
						SceneUtil.addTimedEvent(this.group, new TimedEvent(2.3, 1, stopDrinking));
						
						drink.emitter.counter.stop();
						acid.start = true;
						acid.emitter.counter.resume();
						
						//Close Mouth muscle and re-add Radial hit.
						if(this.group.shellApi.checkEvent(this.events.SPLINTER_REMOVED))
						{
							timeline = this.scene.mouth.get(Timeline);
							timeline.gotoAndPlay("close");
							timeline.reverse = true;
							timeline.handleLabel("open", Command.create(handleLabel, timeline, "open"));
							
							audio = this.scene.mouth.get(Audio);
							audio.play(SoundManager.EFFECTS_PATH + "contract_expand_muscle_0" + Utils.randInRange(1, 2) + ".mp3", false, SoundModifier.POSITION);
							
							mover = new Mover();
							mover.acceleration = new Point(1200, 1200);
							this.group.getEntityById("muscle1").add(mover);
							this.group.getEntityById("doorMouth").add(new Sleep(true, true));
							
							//Open Intestine muscle and remove Radial hit.
							if(this.group.shellApi.checkEvent(this.events.GOT_SHIELD))
							{
								timeline = this.scene.intestine.get(Timeline);
								timeline.gotoAndPlay("open");
								timeline.reverse = false;
								timeline.handleLabel("close", Command.create(handleLabel, timeline, "close"));
								
								audio = this.scene.intestine.get(Audio);
								audio.play(SoundManager.EFFECTS_PATH + "contract_expand_muscle_0" + Utils.randInRange(1, 2) + ".mp3", false, SoundModifier.POSITION);
								
								this.group.getEntityById("muscle2").remove(Mover);
								this.group.getEntityById("doorIntestine").add(new Sleep(false, true));
							}
						}
					}
					break;
				case DIGESTING_STATE:
					//Play sound while food is being digested.
					if (Math.random() < 0.01)
					{
						var audioAcid:Audio = this.group.getEntityById("acidSound").get(Audio);
						audioAcid.play(SoundManager.EFFECTS_PATH + "dissolve_bubbling_01.mp3", false, SoundModifier.POSITION);
					}
					
					if(updateState(time, 5, IDLE_STATE))
					{
						acid.emitter.counter.stop();
						
						//Close Intestine muscle and re-add Radial hit.
						if(this.group.shellApi.checkEvent(this.events.GOT_SHIELD) &&
							this.group.shellApi.checkEvent(this.events.SPLINTER_REMOVED))
						{
							timeline = this.scene.intestine.get(Timeline);
							timeline.gotoAndPlay("close");
							timeline.reverse = true;
							timeline.handleLabel("open", Command.create(handleLabel, timeline, "open"));
							
							audio = this.scene.intestine.get(Audio);
							audio.play(SoundManager.EFFECTS_PATH + "contract_expand_muscle_0" + Utils.randInRange(1, 2) + ".mp3", false, SoundModifier.POSITION);
							
							mover = new Mover();
							mover.acceleration = new Point(0, -1500);
							this.group.getEntityById("muscle2").add(mover);
							this.group.getEntityById("doorIntestine").add(new Sleep(true, true));
						}
					}
					break;
			}
		}
		
		private function updateState(time:Number, waitTime:Number, nextState:String):Boolean
		{
			this.elapsedTime += time;
			if(this.elapsedTime >= waitTime)
			{
				this.elapsedTime = 0;
				this.state = nextState;
				return true;
			}
			return false;
		}
		
		private function startDrinking():void
		{
			this.isDrinking = true;
		}
		
		private function stopDrinking():void
		{
			this.isDrinking = false;
		}
		
		private function handleLabel(timeline:Timeline, label:String):void
		{
			timeline.gotoAndStop(label);
		}
	}
}