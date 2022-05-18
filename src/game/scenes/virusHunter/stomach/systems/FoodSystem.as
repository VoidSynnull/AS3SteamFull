package game.scenes.virusHunter.stomach.systems 
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.motion.WaveMotion;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.hit.Mover;
	import game.data.WaveMotionData;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.stomach.Stomach;
	import game.scenes.virusHunter.stomach.components.Food;
	import game.scenes.virusHunter.stomach.nodes.FoodNode;
	import game.util.Utils;
	
	import org.flintparticles.common.counters.Steady;

	public class FoodSystem extends ListIteratingSystem
	{
		private var state:String;							//Current state of the system
		private var waitTime:Number;						//Wait time for certain system state changes
		private var elapsedTime:Number;						//Determines certain system state changes
		private var numComplete:uint;						//Number of chunks that determine a system state change
		private var emitter:Emitter;						//Stomach acid emitter
		private var scene:Stomach;
		private var events:VirusHunterEvents;
		
		private static const MIN_WAIT_TIME:uint			= 1;	//Minimum wait time for system state changes, Set To: 100
		private static const MAX_WAIT_TIME:uint			= 1;	//Maximum wait time for system state changes, Set To: 150
		private static const FLOAT_HEIGHT:uint 			= 2300; //Hardcoded Y value for food chunks to reach
		
		//FoodSystem states determined by elaspedTime or numComplete
		private static const IDLE_STATE:String 		= "idle_state";
		private static const FALLING_STATE:String 	= "falling_state";
		private static const FLOATING_STATE:String	= "floating_state";
		private static const DIGESTING_STATE:String	= "digesting_state";
		
		public function FoodSystem(scene:Stomach, events:VirusHunterEvents, acid:Entity)
		{
			super(FoodNode, updateNode);
			
			this.state = FoodSystem.IDLE_STATE;
			this.numComplete = 0;
			this.elapsedTime = 0;
			this.waitTime = Utils.randNumInRange(MIN_WAIT_TIME, MAX_WAIT_TIME);
			this.emitter = acid.get(Emitter);
			this.scene = scene;
			this.events = events;
		}
		
		private function updateNode( node:FoodNode, time:Number ):void
		{
			var display:Display = node.display;
			var spatial:Spatial = node.spatial;
			var motion:Motion = node.motion;
			var food:Food = node.food;
			
			var mover:Mover;
			var timeline:Timeline;
			var audio:Audio;
			
			switch(this.state)
			{
				case FoodSystem.IDLE_STATE:
					//Wait for Joe to eat something.
					this.elapsedTime += time;
					if(this.elapsedTime >= this.waitTime)
					{
						this.elapsedTime = 0;
						
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
							
							if(this.group.shellApi.checkEvent(this.events.SPLINTER_REMOVED))
								this.group.getEntityById("doorMouth").add(new Sleep(false, true));
						}
						
						this.state = FoodSystem.FALLING_STATE;
					}
				break;
				
				case FoodSystem.FALLING_STATE:
					switch(food.state)
					{
						case Food.IDLE_STATE:
							//True -> Rice / False -> Meat, Shrooms, Onions
							timeline = node.entity.get(Timeline);
							if(Math.random() > 0.2) timeline.gotoAndStop(3);
							else
							{
								timeline.gotoAndStop(Utils.randInRange(0, 2));
								
								//Scale and flip some chunks for variety.
								spatial.scale = Utils.randNumInRange(0.5, 1);
								if(Math.random() > 0.5) spatial.scaleX *= -1;
							}
							
							//Food chunk spawn/reset point.
							spatial.x = 920;
							spatial.y = 120;
							
							//Set initial Motion for the chunks to fall within the bounds of the acid.
							motion.velocity.x = Utils.randNumInRange(700, 1200);
							motion.velocity.y = 50;
							motion.friction.x = 400;
							motion.rotationFriction = 0;
							motion.rotationVelocity = Utils.randNumInRange(-200, 200);
							motion.acceleration.y = 600;
							
							food.state = Food.SPAWNING_STATE;
						break;
						
						case Food.SPAWNING_STATE:
							//Randomly make chunks fall at different times.
							if(Math.random() < 0.03)
							{
								display.alpha = 1;
								motion.pause = false;
								
								food.state = Food.FALLING_STATE;
							}
						break;
						
						case Food.FALLING_STATE:
							//Chunk has reached the top of the acid.
							if(spatial.y >= FLOAT_HEIGHT)
							{
								var audioSplash:Audio = node.entity.get(Audio);
								var sound:String = "acid_splash_0" + Utils.randInRange(1, 3) + ".mp3";
								audioSplash.play(SoundManager.EFFECTS_PATH + sound, false, SoundModifier.POSITION);
								
								motion.velocity = new Point();
								motion.rotationFriction = 50;
								motion.acceleration.y = 0;
								food.emitter.emitter.start();
								
								food.state = Food.SURFACING_STATE;
							}
						break;
						
						case Food.SURFACING_STATE:
							motion.acceleration.y = -5 - (spatial.y - FLOAT_HEIGHT) * 5;
							if(spatial.y <= FLOAT_HEIGHT)
							{
								this.numComplete++;
								
								//Reset Motion and set Spatial. Some acceleration persists if
								//previousAcceleartion isn't reset for some reason.
								spatial.y = 2300;
								motion.velocity = new Point();
								motion.acceleration = new Point();
								motion.previousAcceleration = new Point();
								
								//Left/right acid bobbing.
								var wave:WaveMotion = new WaveMotion();
								var waveData:WaveMotionData = new WaveMotionData();
								waveData.property = "rotation";
								waveData.magnitude = 5;
								waveData.rate = 0.08;
								waveData.radians = Utils.randNumInRange(Math.PI/2, Math.PI);
								wave.data.push(waveData);
								
								//Up/down acid bobbing.
								waveData = new WaveMotionData();
								waveData.property = "y";
								waveData.magnitude = 4;
								waveData.rate = Utils.randNumInRange(0.05, 0.075);
								wave.data.push(waveData);
								
								//Add components. The WaveMotionSystem needs a
								//SpatialAddition to place the Spatial correctly.
								node.entity.add(wave);
								node.entity.add(new SpatialAddition());
								
								food.state = Food.FLOATING_STATE;
							}
						break;
					}
					
					//All chunks have fallen.
					if(this.numComplete >= Stomach(this.group).numChunks)
					{
						this.numComplete = 0;
						this.waitTime = Utils.randNumInRange(MIN_WAIT_TIME, MAX_WAIT_TIME);
						
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
						}
						
						this.state = FoodSystem.FLOATING_STATE;
					}
					break;
				
				case FoodSystem.FLOATING_STATE:
					//Wait for all chunks to float for a while.
					this.elapsedTime += time;
					if(this.elapsedTime >= this.waitTime)
					{
						this.elapsedTime = 0;
						this.emitter.start = true;
						this.emitter.emitter.counter.resume();
						
						//Open Intestine muscle and remove Radial hit.
						if(this.group.shellApi.checkEvent(this.events.GOT_SHIELD) &&
							this.group.shellApi.checkEvent(this.events.SPLINTER_REMOVED))
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
						
						this.state = FoodSystem.DIGESTING_STATE;
					}
				break;
				
				case FoodSystem.DIGESTING_STATE:
					switch(food.state)
					{
						case Food.FLOATING_STATE:
							//Randomly sink the chunk into the acid.
							motion.friction.y = Utils.randNumInRange(10, 30);
							motion.acceleration.y = Utils.randNumInRange(20, 70);
							
							//Randomly deteriorate the chunk.
							food.alphaRate = Utils.randNumInRange(0.005, 0.03);
							food.scaleRate = Utils.randNumInRange(0.005, 0.01);
							
							food.state = Food.DIGESTING_STATE;
						break;
						
						case Food.DIGESTING_STATE:
							//Randomly digest the chunk.
							display.alpha -= food.alphaRate;
							
							//Make sure the random number doesn't flip the clip when it's shrunk.
							if(Math.abs(spatial.scaleX) - food.scaleRate > 0)
							{
								//Some chunks are randomly flipped on the X just for some directional variety.
								//Because of this, spatials must be scaled differently.
								if(spatial.scaleX > 0)
								{
									spatial.scaleX -= food.scaleRate;
									spatial.scaleY -= food.scaleRate;
								}
								else
								{
									spatial.scaleX += food.scaleRate;
									spatial.scaleY -= food.scaleRate;
								}
							}
							else spatial.scale = 0;
							
							//Fully digested. Return food to normal.
							if(display.alpha <= 0)
							{
								this.numComplete++;
								motion.pause = true;
								display.alpha = 0;
								spatial.scaleX = 1;
								spatial.scaleY = 1;
								node.entity.remove(WaveMotion);
								node.entity.remove(SpatialAddition);
								
								food.state = Food.IDLE_STATE;
							}
							break;
					}
					
					//Play a steam sound while food is being digested.
					if (Math.random() < 0.01)
					{
						var audioAcid:Audio = this.group.getEntityById("acidSound").get(Audio);
						//var soundAcid:String = "steam_0" + Utils.randInRange(1, 2) + ".mp3";
						var soundAcid:String = "dissolve_bubbling_01.mp3";
						audioAcid.play(SoundManager.EFFECTS_PATH + soundAcid, false, SoundModifier.POSITION);
					}
					
					//Adjust number of acid particles by how many chunks have been deteriorated.
					Steady(this.emitter.emitter.counter).rate = 15 + (10 * this.numComplete);
					
					//All chunks have been digested.
					if(this.numComplete >= Stomach(this.group).numChunks)
					{
						this.numComplete = 0;
						this.waitTime = Utils.randNumInRange(MIN_WAIT_TIME, MAX_WAIT_TIME);
						this.emitter.emitter.counter.stop();
						
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
						
						this.state = FoodSystem.IDLE_STATE;
					}
				break;
			}
		}
		
		private function handleLabel(timeline:Timeline, label:String):void
		{
			timeline.gotoAndStop(label);
		}
	}
}