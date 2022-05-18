package game.scenes.arab3.vizierRoom.popups
{
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.motion.ShakeMotion;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.ui.TransitionData;
	import game.particles.emitter.specialAbility.FlameBlast;
	import game.scenes.arab1.shared.particles.EmberParticles;
	import game.scenes.arab3.Arab3Events;
	import game.systems.motion.ShakeMotionSystem;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.osflash.signals.Signal;
	
	public class AlchemyTable2 extends Popup
	{
		private const FUZE_SOUND:String = SoundManager.EFFECTS_PATH + "lit_fuse_01_L.mp3";
		private const PUFF_SOUND:String = SoundManager.EFFECTS_PATH + "poof_02.mp3";
		private const GRIND_SOUND:String = SoundManager.EFFECTS_PATH + "grinding_stone_01.mp3";
		private const CLEAR_SOUND:String = SoundManager.EFFECTS_PATH + "trip_01.mp3";
		private const COMBINE_SOUND:String = SoundManager.EFFECTS_PATH + "majong_slide_01.mp3";
		
		private const OIL_SOUND:String = SoundManager.EFFECTS_PATH + "ls_mud_slide_01.mp3";
		private const BONE_MEAL_SOUND:String = SoundManager.EFFECTS_PATH + "sand_impact_01.mp3";
		private const BURLAP_SOUND:String = SoundManager.EFFECTS_PATH + "scissor_cut_01.mp3";
		private const MOONSTONE_SOUND:String = SoundManager.EFFECTS_PATH + "sand_impact_02.mp3";
		private const FEATHER_SOUND:String = SoundManager.EFFECTS_PATH + "put_misc_item_down_01.mp3";
		
		private const BOOK:String = SoundManager.EFFECTS_PATH +"falling_paper_01.mp3";
		
		
		public const BONE_MEAL:String = "bone";
		public const MOONSTONE:String = "moon";
		public const BURLAP_SACK:String = "sack";
		public const SESAME_OIL:String = "oil";
		public const ROC_FEATHER:String = "roc";
		
		private var bonemeal:Entity;
		private var moonstone:Entity;
		private var burlap:Entity;
		private var sesameoil:Entity;
		private var rocfeather:Entity;
		
		private var mixer:Entity;
		
		private var divination:Entity;
		private var levitation:Entity;
		
		private var recipeDivine:Dictionary;
		private var recipeLevitation:Dictionary;
		
		private var ingredientSamples:Array;
		private var currentIndex:int = 0;
		
		private var bonemealTotal:int = 2;
		private var moonstoneTotal:int = 3;
		private var burlapTotal:int = 1;
		private var sesameoilTotal:int = 0;
		private var rocfeatherTotal:int = 0;
		
		private var bonemealCount:int = 0;
		private var moonstoneCount:int = 0;
		private var burlapCount:int = 0;
		private var sesameoilCount:int = 0
		private var rocfeatherCount:int = 0
		
		private var _events:Arab3Events;
		
		public var completeSignal:Signal;
		private var product:String;
		private var book:Entity;
		
		public function AlchemyTable2(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			super.transitionOut = super.transitionIn.duplicateSwitch();
			super.darkenBackground = true;
			super.groupPrefix = "scenes/arab3/vizierRoom/popups/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["vizierAlchemyTable.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{				
			super.screen = super.getAsset("vizierAlchemyTable.swf", true) as MovieClip;
			
			this.letterbox(super.screen.content);
			
			this.darkenAlpha = 0.85;
			super.loadCloseButton();
			super.loaded();
			
			addSystem(new ShakeMotionSystem());
			
			setupPuzzle();
		}
		
		private function setupPuzzle():void
		{
			recipeDivine = new Dictionary();
			recipeDivine[BONE_MEAL]		= 2;
			recipeDivine[MOONSTONE]		= 3;
			recipeDivine[BURLAP_SACK]	= 1;
			recipeDivine[SESAME_OIL]	= 0;
			recipeDivine[ROC_FEATHER]	= 0;
			
			recipeLevitation = new Dictionary();
			recipeLevitation[BONE_MEAL]		= 0;
			recipeLevitation[MOONSTONE]		= 2;
			recipeLevitation[BURLAP_SACK]	= 0;
			recipeLevitation[SESAME_OIL]	= 3;
			recipeLevitation[ROC_FEATHER]	= 1;
			
			// bitmap EVERYTHING
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				BitmapUtils.convertContainer(screen.content["BG"],PerformanceUtils.defaultBitmapQuality);
				BitmapUtils.convertContainer(screen.content[BONE_MEAL],PerformanceUtils.defaultBitmapQuality);
				BitmapUtils.convertContainer(screen.content[MOONSTONE],PerformanceUtils.defaultBitmapQuality);
				BitmapUtils.convertContainer(screen.content[BURLAP_SACK],PerformanceUtils.defaultBitmapQuality);
				BitmapUtils.convertContainer(screen.content[SESAME_OIL],PerformanceUtils.defaultBitmapQuality);
				BitmapUtils.convertContainer(screen.content[ROC_FEATHER],PerformanceUtils.defaultBitmapQuality);
				BitmapUtils.convertContainer(screen.content["book"],PerformanceUtils.defaultBitmapQuality);
				BitmapUtils.convertContainer(screen.content["mixer"],PerformanceUtils.defaultBitmapQuality);
				var sharedPieceTL:BitmapSequence = BitmapTimelineCreator.createSequence(screen.content["piece0"]);
			}
			// load ingredient supply buttons	
			bonemeal = EntityUtils.createSpatialEntity(this,screen.content[BONE_MEAL],screen.content);	
			moonstone = EntityUtils.createSpatialEntity(this,screen.content[MOONSTONE],screen.content);
			burlap = EntityUtils.createSpatialEntity(this,screen.content[BURLAP_SACK],screen.content);
			sesameoil = EntityUtils.createSpatialEntity(this,screen.content[SESAME_OIL],screen.content);
			rocfeather = EntityUtils.createSpatialEntity(this,screen.content[ROC_FEATHER],screen.content);
			book = EntityUtils.createSpatialEntity(this, screen.content["book"], screen.content);
			
			
			var inter:Interaction = InteractionCreator.addToEntity(bonemeal,[InteractionCreator.CLICK]);
			inter.click.add(Command.create(placeIngredient, BONE_MEAL));
			ToolTipCreator.addToEntity(bonemeal);
			
			inter = InteractionCreator.addToEntity(moonstone,[InteractionCreator.CLICK]);
			inter.click.add(Command.create(placeIngredient, MOONSTONE));
			ToolTipCreator.addToEntity(moonstone);
			
			inter = InteractionCreator.addToEntity(burlap,[InteractionCreator.CLICK]);
			inter.click.add(Command.create(placeIngredient, BURLAP_SACK));
			ToolTipCreator.addToEntity(burlap);
			
			inter = InteractionCreator.addToEntity(sesameoil,[InteractionCreator.CLICK]);
			inter.click.add(Command.create(placeIngredient, SESAME_OIL));
			ToolTipCreator.addToEntity(sesameoil);
			
			inter = InteractionCreator.addToEntity(rocfeather,[InteractionCreator.CLICK]);
			inter.click.add(Command.create(placeIngredient, ROC_FEATHER));
			ToolTipCreator.addToEntity(rocfeather);
			
			inter = InteractionCreator.addToEntity(book,[InteractionCreator.CLICK]);
			inter.click.add(Command.create(openBook));
			ToolTipCreator.addToEntity(book);
			
			// combine button
			mixer = EntityUtils.createSpatialEntity(this,screen.content["mixer"],screen.content);
			inter = InteractionCreator.addToEntity(mixer,[InteractionCreator.CLICK]);
			inter.click.add(Command.create(combineIngredients));
			ToolTipCreator.addToEntity(mixer);
			
			if(!shellApi.checkHasItem(_events.BURLAP_SACK)){
				removeEntity(burlap);
			}
			if(!shellApi.checkHasItem(_events.MOON_DUST)){
				removeEntity(moonstone);
			}			
			if(!shellApi.checkHasItem(_events.BONE_MEAL)){
				removeEntity(bonemeal);
			}			
			if(!shellApi.checkHasItem(_events.SESAME_OIL)){
				removeEntity(sesameoil);
			}			
			if(!shellApi.checkHasItem(_events.ROC_FEATHER)){
				removeEntity(rocfeather);
			}
			if(!shellApi.checkHasItem(_events.MAGIC_BOOK)){
				removeEntity(book);
				product = "noBook";
				SceneUtil.lockInput(this, true);
				SceneUtil.addTimedEvent(this, new TimedEvent(1,1,deliverResult));
			}
			// products created on success
			divination = EntityUtils.createSpatialEntity(this, screen.content["divination"],screen.content);
			levitation = EntityUtils.createSpatialEntity(this, screen.content["levitation"],screen.content);
			divination.get(Display).visible=false;
			levitation.get(Display).visible=false;
			
			// little ingredient pieces
			ingredientSamples = new Array();
			var piece:Entity;
			var clip:MovieClip = screen.content["piece"+0];
			for (var i:int = 0; i < 6; i++) 
			{
				clip = screen.content["piece"+i];
				if(sharedPieceTL){
					piece = BitmapTimelineCreator.createBitmapTimeline(clip,true,true,sharedPieceTL,PerformanceUtils.defaultBitmapQuality);
					addEntity(piece);
				}
				else{
					piece = EntityUtils.createMovingTimelineEntity(this, clip, screen.content);
				}
				inter = InteractionCreator.addToEntity(piece,[InteractionCreator.CLICK]);
				inter.click.add(clearIngredients);
				ToolTipCreator.addToEntity(piece);
				Timeline(piece.get(Timeline)).gotoAndStop("empty");
				ingredientSamples.push(piece);
			}
			
			var center:MovieClip = screen.content["center"];
			center.mouseChildren = false;
			center.mouseEnabled = false;
			center = screen.content["center2"];
			center.mouseChildren = false;
			center.mouseEnabled = false;
		}
		
		private function openBook(...p):void
		{
			AudioUtils.play(this, BOOK);
			var popup:MagicBookPopup = this.addChildGroup(new MagicBookPopup(this.container)) as MagicBookPopup;
		}
		
		private function clearIngredients(ent:*):void
		{
			for each (var piece:Entity in ingredientSamples) 
			{
				Timeline(piece.get(Timeline)).gotoAndStop("empty");
			}
			bonemealCount = 0;
			moonstoneCount = 0;
			burlapCount = 0;
			sesameoilCount = 0;
			rocfeatherCount = 0;
			currentIndex = 0;
			AudioUtils.play(this, CLEAR_SOUND, 1,false,null,null,1.5);
		}
		
		private function combineIngredients(...p):void
		{
			// lock input, converge ingredients, do something fancy, if sucessfull, show a lit bomb on the table and force exit
			SceneUtil.lockInput(this,true);
			var center:MovieClip = screen.content["center"];
			center.mouseChildren = false;
			center.mouseEnabled = false;
			for each (var piece:Entity in ingredientSamples) 
			{
				TweenUtils.entityTo(piece, Spatial, 0.5, {x:center.x, y:center.y});
			}
			TweenUtils.entityTo(mixer, Spatial, 1.0, {x:center.x, y:center.y - 50, onComplete:smash});
			// SOUND
			AudioUtils.play(this, COMBINE_SOUND, 1,false,null,null,1.5);
		}
		
		private function smash():void
		{
			AudioUtils.play(this, GRIND_SOUND, 1,false,null,null,1.1);
			// shake mixer a bit, check result
			mixer.add(new ShakeMotion(new RectangleZone(-7, -7, 7, 7)));
			mixer.add(new SpatialAddition());
			SceneUtil.addTimedEvent(this, new TimedEvent(1.5,1,checkResult));
		}
		
		private function checkResult():void
		{
			// put mixer back
			var center2:MovieClip = screen.content["center2"];
			center2.mouseChildren = false;
			center2.mouseEnabled = false;
			TweenUtils.entityTo(mixer, Spatial, 0.4, {x:center2.x, y:center2.y});
			mixer.remove(ShakeMotion);
			AudioUtils.stop(this, GRIND_SOUND);
			var label:String;
			var tl:Timeline;
			// count each ingredient, success if totals reached
			for each (var piece:Entity in ingredientSamples) 
			{
				tl = Timeline(piece.get(Timeline));
				tl.gotoAndStop("empty");
				label = tl.data.getFrame(tl.currentIndex).label;
				if(label == BONE_MEAL){
					bonemealCount++;
				}
				else if(label == MOONSTONE){
					moonstoneCount++;
				}
				else if(label == BURLAP_SACK){
					burlapCount++;
				}
				else if(label == SESAME_OIL){
					sesameoilCount++;
				}
				else if(label == ROC_FEATHER){
					rocfeatherCount++;
				}
			}
			
			product = getProduct();
			// close and trigger relevant events
			// poof
			var center:MovieClip = screen.content["center"];
			makePoof(center.x, center.y);
			SceneUtil.addTimedEvent(this, new TimedEvent(1.6,1,deliverResult));
		}
		
		private function getProduct():String
		{
			var product:String = "NOTHING";
			// check recipes
			var success:Boolean = (bonemealCount == recipeDivine[BONE_MEAL])
				&&(moonstoneCount == recipeDivine[MOONSTONE])
				&&(burlapCount == recipeDivine[BURLAP_SACK])
				&&(sesameoilCount == recipeDivine[SESAME_OIL])
				&&(rocfeatherCount == recipeDivine[ROC_FEATHER]);
			if(success){
				product = "divination_dust";
				divination.get(Display).visible = true;
			}
			else{
				success = (bonemealCount == recipeLevitation[BONE_MEAL])
					&&(moonstoneCount == recipeLevitation[MOONSTONE])
					&&(burlapCount == recipeLevitation[BURLAP_SACK])
					&&(sesameoilCount == recipeLevitation[SESAME_OIL])
					&&(rocfeatherCount == recipeLevitation[ROC_FEATHER]);
				if(success){
					product = "magic_carpet";
					floatPotion();
				}
			}
			
			return product;
		}
		
		private function floatPotion():void
		{
			levitation.get(Display).visible = true;
			// particles + wave motion
			MotionUtils.addWaveMotion(levitation, new WaveMotionData("y", 0.5,0.05, "sin"));
		}
		
		private function deliverResult():void
		{
			SceneUtil.lockInput(this,false);
			this.popupRemoved.add(Command.create(completeSignal.dispatch,product));
			close(true);
		}
		
		private function makePoof( x:Number, y:Number ):void
		{
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(new Blob(30, 0xFFFFFF));
			
			var puff:FlameBlast = new FlameBlast();
			puff.counter = new Blast( 25);
			puff.addInitializer(new Lifetime(0.2, 0.35));
			puff.addInitializer(new Velocity(new DiscSectorZone(new Point(0,0), 300, 200, -Math.PI, Math.PI )));
			puff.addInitializer(new Position(new DiscZone(new Point(0,0), 18)));
			puff.addInitializer(new BitmapImage(bitmapData, true, 6));
			puff.addAction(new Age());
			puff.addAction(new Move());
			puff.addAction(new RotateToDirection());
			puff.addAction(new Fade(0.95,0.0));
			EmitterCreator.create(this,screen.content,puff,x,y);
			AudioUtils.play(this, PUFF_SOUND, 1,false,null,null,1.5);
		}
		
		private function placeIngredient(x:*,ingredient:String):void
		{
			Timeline(ingredientSamples[currentIndex].get(Timeline)).gotoAndStop(ingredient);
			currentIndex++;
			if(currentIndex > ingredientSamples.length-1){
				currentIndex=0;
			}
			// SOUND
			placeSound(ingredient);
		}
		private function placeSound(ingredient:String):void
		{
			switch(ingredient)
			{
				case BONE_MEAL:
				{
					AudioUtils.play(this, BONE_MEAL_SOUND, 1,false,null,null,1.0);
					break;
				}
				case MOONSTONE:
				{
					AudioUtils.play(this, MOONSTONE_SOUND, 1,false,null,null,1.0);
					break;
				}
				case BURLAP_SACK:
				{
					AudioUtils.play(this, BURLAP_SOUND, 1,false,null,null,0.9);
					break;
				}
				case SESAME_OIL:
				{
					AudioUtils.play(this, OIL_SOUND, 1,false,null,null,0.9);
					break;
				}		
				case ROC_FEATHER:
				{
					AudioUtils.play(this, FEATHER_SOUND, 1.2,false,null,null,1.0);
					break;
				}
				default:
				{
					AudioUtils.play(this, BONE_MEAL_SOUND, 1,false,null,null,1.0);
					break;
				}
			}
		}
		
		override public function close(removeOnClose:Boolean=true, onCloseHandler:Function=null):void
		{
			//SceneUtil.lockInput(this, false);
			super.close(removeOnClose,onCloseHandler);
		}
	}
}


