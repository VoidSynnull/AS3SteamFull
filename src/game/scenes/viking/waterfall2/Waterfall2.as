package game.scenes.viking.waterfall2
{
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.SpatialAddition;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.hit.Platform;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.data.WaveMotionData;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.viking.VikingEvents;
	import game.scenes.viking.shared.fishing.HandFishingGroup;
	import game.scenes.viking.shared.popups.MapPopup;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TriggerEventAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.motion.SceneObjectMotionSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.RotateVelocity;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.osflash.signals.Signal;
	
	public class Waterfall2 extends PlatformerGameScene
	{
		private var fishingGroup:HandFishingGroup;
		private var _events:VikingEvents;
		private var FALLS:String = SoundManager.EFFECTS_PATH + "waterfall.mp3";
		
		public function Waterfall2()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/viking/waterfall2/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			setupMapDoor();
			
			setupFallsParticles();
			
			setupWaterAnims();
			
			if(shellApi.checkEvent(_events.PEAK_EXPLODED)){
				if(!shellApi.checkEvent(_events.SAW_RIVER_CHANGE)){
					if(shellApi.sceneManager.previousScene == "peak"){
						lookAtWater();
					}else{
						lookAtWater(false);
					}
				}
			}
			
			fishingGroup = addChildGroup(new HandFishingGroup(_hitContainer)) as HandFishingGroup;
			
			setupLog();
		}
		
		private function setupLog():void
		{
			super.addSystem(new WaveMotionSystem());
			super.addSystem( new SceneObjectMotionSystem() );
			
			
			var tree:Entity = EntityUtils.createMovingEntity(this,_hitContainer["tree"]);
			var hitEntity:Entity = super.getEntityById("log");

			if( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGHEST ) { 
				BitmapUtils.createBitmapSprite(EntityUtils.getDisplayObject(tree)); 
			}
			tree.add( new Sleep(false, true));

			MotionUtils.addWaveMotion( tree, new WaveMotionData( "y", 6, 0.05 , "cos" ), this );
			WaveMotion(tree.get(WaveMotion)).data.push(new WaveMotionData( "rotation", 3, 0.02 , "cos" ));
			hitEntity.get(Display).visible = false;
			hitEntity.add(tree.get(SpatialAddition));
						
			Display(tree.get(Display)).moveToFront();
		}
		
		private function lookAtWater(move:Boolean = true):void
		{
			var toprock:Entity = getEntityById("top");
			toprock.remove(Platform);
			var actions:ActionChain = new ActionChain(this);
			actions.lockInput = true;
			
			actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection,player,true)));
			actions.addAction(new WaitAction(0.5));
			if(move){
				actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection,player,false)));
				actions.addAction(new MoveAction(player, getEntityById("targetZone3"),new Point(30,60),NaN, true));
				actions.addAction(new WaitAction(0.5));
				actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection,player,true)));
			}
			actions.addAction(new PanAction(getEntityById("targetZone"),0.05));
			actions.addAction(new WaitAction(1.2));
			actions.addAction(new PanAction(player, 0.05));
			actions.addAction(new TalkAction(player, "river"));
			actions.addAction(new PanAction(player));
			actions.addAction(new TriggerEventAction(_events.SAW_RIVER_CHANGE,true));
			actions.addAction(new CallFunctionAction(Command.create(toprock.add,new Platform())));
			
			actions.execute();
		}		
		
		private function setupFallsParticles():void
		{
			var bubbleParts:Emitter2D;
			var bitmapData:BitmapData;
			var fallsBot:MovieClip;
			var fallsBotEntity:Entity;
			var fallsBounds:Rectangle;
			for (var i:int = 1; _hitContainer["fallsBot" + i] != null; i++) 
			{		
				fallsBot = _hitContainer["fallsBot"+i];
				fallsBounds = fallsBot.getBounds(_hitContainer);
				fallsBotEntity = EntityUtils.createSpatialEntity(this, fallsBot, _hitContainer);
				
				bubbleParts = new Emitter2D();
				bitmapData = BitmapUtils.createBitmapData( new Blob( 11, 0xC8E6EE ));
				bubbleParts.counter = new Steady( fallsBounds.width / 7);
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					bubbleParts.counter = new Steady( fallsBounds.width / 14 );
				}
				bubbleParts.addInitializer( new BitmapImage( bitmapData, true, 20 ));
				bubbleParts.addInitializer(new Position(new LineZone(new Point(fallsBounds.left,fallsBounds.bottom),fallsBounds.bottomRight)));
				bubbleParts.addInitializer( new Velocity( new LineZone( new Point( -10, 0 ), new Point( -10, -20 ))));
				bubbleParts.addInitializer(new Lifetime(1.1));
				bubbleParts.addInitializer(new ScaleImageInit(0.7));
				bubbleParts.addInitializer(new RotateVelocity(2.0,4.0));
				
				bubbleParts.addAction( new ScaleImage( 1, 2.2 ));
				bubbleParts.addAction( new Fade( .76, 0 ));	
				bubbleParts.addAction(new Move());
				bubbleParts.addAction(new Age());
				bubbleParts.addAction(new Accelerate(0,-40));
				
				EmitterCreator.create( this, _hitContainer, bubbleParts, 0, 0, fallsBotEntity);
				// SOUND
				AudioUtils.playSoundFromEntity(fallsBotEntity, FALLS, 500, 0.05, 0.9, null, true);
			}
			Display(player.get(Display)).moveToFront();
		}
		
		private function setupWaterAnims():void
		{
			var bitSeq:BitmapSequence;
			var bub:Entity;
			var tl:Timeline;
			for (var i:int = 0; _hitContainer["fallsTop"+i]; i++) 
			{
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					if(!bitSeq){
						bitSeq = BitmapTimelineCreator.createSequence(_hitContainer["fallsTop"],true,PerformanceUtils.defaultBitmapQuality);
					}
					bub = BitmapTimelineCreator.createBitmapTimeline(_hitContainer["fallsTop"+i],true,true,bitSeq,PerformanceUtils.defaultBitmapQuality);
					addEntity(bub);
				}
				else{
					bub = EntityUtils.createMovingTimelineEntity(this, _hitContainer["fallsTop"+i]);
				}
				tl = bub.get(Timeline);
				bub.add(new Sleep());
				tl.currentIndex = GeomUtils.randomInt(0, tl.totalFrames-1);
				tl.gotoAndPlay(tl.currentIndex);
			}	
			bitSeq = null;
			for (var j:int = 1; _hitContainer["ripple0"+j]; j++) 
			{
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					if(!bitSeq){
						bitSeq = BitmapTimelineCreator.createSequence(_hitContainer["ripple01"],true,PerformanceUtils.defaultBitmapQuality);
					}
					bub = BitmapTimelineCreator.createBitmapTimeline(_hitContainer["ripple0"+j],true,true,bitSeq,PerformanceUtils.defaultBitmapQuality);
					addEntity(bub);
				}
				else{
					bub = EntityUtils.createMovingTimelineEntity(this, _hitContainer["ripple0"+j]);
				}
				tl = bub.get(Timeline);
				bub.add(new Sleep());
				tl.currentIndex = GeomUtils.randomInt(0, tl.totalFrames-1);
				tl.gotoAndPlay(tl.currentIndex);
			}	
		}
		
		private function setupMapDoor():void	
		{
			var door:Entity = super.getEntityById("doorMap");
			var scenenteraction:SceneInteraction = door.get(SceneInteraction);
			var interaction:Interaction = door.get(Interaction);
			scenenteraction.offsetX = 0;
			interaction.click = new Signal();
			interaction.click.add(openMap);			
		}
		
		private function openMap(door:Entity):void
		{
			var mapPopup:MapPopup = new MapPopup(overlayContainer);
			addChildGroup(mapPopup);
		}
	}
}