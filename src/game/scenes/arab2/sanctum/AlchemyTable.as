package game.scenes.arab2.sanctum
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
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
	import game.data.ui.TransitionData;
	import game.particles.emitter.specialAbility.FlameBlast;
	import game.scenes.arab1.shared.particles.EmberParticles;
	import game.scenes.arab2.Arab2Events;
	import game.scenes.arab2.shared.FormulaPopup;
	import game.systems.motion.ShakeMotionSystem;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.osflash.signals.Signal;
	
	public class AlchemyTable extends Popup
	{
		private const FUZE_SOUND:String = SoundManager.EFFECTS_PATH + "lit_fuse_01_L.mp3";
		private const PUFF_SOUND:String = SoundManager.EFFECTS_PATH + "poof_02.mp3";
		private const GRIND_SOUND:String = SoundManager.EFFECTS_PATH + "grinding_stone_01.mp3";
		private const CLEAR_SOUND:String = SoundManager.EFFECTS_PATH + "trip_01.mp3";
		private const COMBINE_SOUND:String = SoundManager.EFFECTS_PATH + "majong_slide_01.mp3";
		
		private const QUICKSILVER_SOUND:String = SoundManager.EFFECTS_PATH + "ls_mud_slide_01.mp3";
		private const BORAX_SOUND:String = SoundManager.EFFECTS_PATH + "sand_impact_01.mp3";
		private const SNAKESKIN_SOUND:String = SoundManager.EFFECTS_PATH + "snake_hiss_03.mp3";
		private const GUNPOWDER_SOUND:String = SoundManager.EFFECTS_PATH + "sand_impact_02.mp3";
		
		
		public const QUICKSILVER:String = "quicksilver";
		public const BORAX:String = "borax";
		public const SNAKESKIN:String = "snakeskin";
		public const GUNPOWDER:String = "gunpowder";
		
		private var sucess:Boolean = false;
		
		private var quicksilver:Entity;
		private var borax:Entity;
		private var snakeskin:Entity;
		private var gunpowder:Entity;
		
		private var mixer:Entity;
		private var litBomb:Entity;
		
		private var ingredientSamples:Array;
		private var currentIndex:int = 0;
		
		private var quicksilverTotal:int = 3;
		private var boraxTotal:int = 2;
		private var snakeskinTotal:int = 1;
		private var gunpowderTotal:int = 2;
		
		private var quicksilverCount:int = 0;
		private var boraxCount:int = 0;
		private var snakeskinCount:int = 0
		private var gunpowderCount:int = 0
		
		private var _events:Arab2Events;
		
		public var completeSignal:Signal;
		private var formula:Entity;
		
		public function AlchemyTable(container:DisplayObjectContainer=null)
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
			super.groupPrefix = "scenes/arab2/sanctum/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["alchemy_table.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{				
			super.screen = super.getAsset("alchemy_table.swf", true) as MovieClip;
			
			this.letterbox(super.screen.content);
			//super.screen.content.y += 10;
			
			this.darkenAlpha = 0.85;
			super.loadCloseButton();
			super.loaded();
			
			addSystem(new ShakeMotionSystem());
			
			setupPuzzle();
		}
		
		private function setupPuzzle():void
		{
			
			// bitmap EVERYTHING
			if(PlatformUtils.isMobileOS){
				convertContainer(screen);
				var sharedPieceTL:BitmapSequence = BitmapTimelineCreator.createSequence(screen.content["piece0"]);
			}
			// load ingredient supply buttons	
			quicksilver = EntityUtils.createSpatialEntity(this,screen.content[QUICKSILVER],screen.content);	
			borax = EntityUtils.createSpatialEntity(this,screen.content[BORAX],screen.content);
			snakeskin = EntityUtils.createSpatialEntity(this,screen.content[SNAKESKIN],screen.content);
			gunpowder = EntityUtils.createSpatialEntity(this,screen.content[GUNPOWDER],screen.content);
			
			var inter:Interaction = InteractionCreator.addToEntity(quicksilver,[InteractionCreator.CLICK]);
			inter.click.add(Command.create(placeIngredient, QUICKSILVER));
			ToolTipCreator.addToEntity(quicksilver);
			
			inter = InteractionCreator.addToEntity(borax,[InteractionCreator.CLICK]);
			inter.click.add(Command.create(placeIngredient, BORAX));
			ToolTipCreator.addToEntity(borax);
			
			inter = InteractionCreator.addToEntity(snakeskin,[InteractionCreator.CLICK]);
			inter.click.add(Command.create(placeIngredient, SNAKESKIN));
			ToolTipCreator.addToEntity(snakeskin);
			
			inter = InteractionCreator.addToEntity(gunpowder,[InteractionCreator.CLICK]);
			inter.click.add(Command.create(placeIngredient, GUNPOWDER));
			ToolTipCreator.addToEntity(gunpowder);
			
			// combine button
			mixer = EntityUtils.createSpatialEntity(this,screen.content["mixer"],screen.content);
			inter = InteractionCreator.addToEntity(mixer,[InteractionCreator.CLICK]);
			inter.click.add(Command.create(combineIngredients));
			ToolTipCreator.addToEntity(mixer);
			formula = EntityUtils.createSpatialEntity(this,screen.content["formula"],screen.content);
			inter = InteractionCreator.addToEntity(formula,[InteractionCreator.CLICK]);
			inter.click.add(Command.create(openFormula));
			ToolTipCreator.addToEntity(formula);
			// bomb created for sucess
			litBomb = EntityUtils.createSpatialEntity(this,screen.content["litBomb"],screen.content);
			Display(litBomb.get(Display)).visible = false;
			// little ingredient pieces
			ingredientSamples = new Array();
			var piece:Entity;
			var clip:MovieClip = screen.content["piece"+0];
			for (var i:int = 0; i < 8; i++) 
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
		}
		
		private function openFormula(...p):void
		{
			var caughtPopup:FormulaPopup = new FormulaPopup(this.container);
			caughtPopup.id = "forumalPop";
			this.addChildGroup(caughtPopup);
		}
		
		private function clearIngredients(ent:*):void
		{
			for each (var piece:Entity in ingredientSamples) 
			{
				Timeline(piece.get(Timeline)).gotoAndStop("empty");
			}
			quicksilverCount = 0;
			boraxCount = 0;
			snakeskinCount = 0;
			gunpowderCount = 0;
			currentIndex = 0;
			AudioUtils.play(this, CLEAR_SOUND, 1,false,null,null,1.5);
		}
		
		private function combineIngredients(...p):void
		{
			// lock input, converge ingredients, do something fancy, if sucessfull, show a lit bomb on the table and force exit
			SceneUtil.lockInput(this,true);
			var center:MovieClip = screen.content["center"];
			for each (var piece:Entity in ingredientSamples) 
			{
				TweenUtils.entityTo(piece, Spatial, 0.5, {x:center.x, y:center.y});
			}
			TweenUtils.entityTo(mixer, Spatial, 1.0, {x:center.x, y:center.y - 100, onComplete:smash});
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
			var clip:MovieClip = screen.content["center2"];
			TweenUtils.entityTo(mixer, Spatial, 0.4, {x:clip.x, y:clip.y});
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
				if(label == QUICKSILVER){
					quicksilverCount++;
				}
				else if(label == BORAX){
					boraxCount++;
				}
				else if(label == SNAKESKIN){
					snakeskinCount++;
				}
				else if(label == GUNPOWDER){
					gunpowderCount++;
				}
			}
			sucess = (quicksilverCount == quicksilverTotal)
				&&(boraxCount == boraxTotal)
				&&(snakeskinCount == snakeskinTotal)
				&&(gunpowderCount == gunpowderTotal);
			// close and trigger relevant events
			if(sucess){
				showBomb();
			}
			// poof
			makePoof(1031,696);
			SceneUtil.addTimedEvent(this, new TimedEvent(1.6,1,deliverResult));
		}
		
		private function deliverResult():void
		{
			this.popupRemoved.add(Command.create(completeSignal.dispatch,sucess));
			close(true);
		}
		
		private function showBomb(...p):void
		{
			Display(litBomb.get(Display)).visible = true;
			// create sparkles
			var emberParticles:EmberParticles = new EmberParticles();
			EmitterCreator.create(this, screen.content, emberParticles, 0, 0, litBomb, null, litBomb.get(Spatial));
			emberParticles.init(this, 0xff9900, 0xffff99, 7, 30, -140, -5);
			emberParticles.stream();
			AudioUtils.play(this, FUZE_SOUND, 1,false,null,null,1.1);
		}
		
		private function makePoof( x:Number, y:Number ):void
		{
			var puff:FlameBlast = new FlameBlast();
			puff.counter = new Blast( 25);
			puff.addInitializer(new Lifetime(0.2, 0.35));
			puff.addInitializer(new Velocity(new DiscSectorZone(new Point(0,0), 300, 200, -Math.PI, Math.PI )));
			puff.addInitializer(new Position(new DiscZone(new Point(0,0), 18)));
			puff.addInitializer(new ImageClass(Blob, [30,0xffffff], true, 6));
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
				case QUICKSILVER:
				{
					AudioUtils.play(this, QUICKSILVER_SOUND, 1,false,null,null,1.2);
					break;
				}
				case BORAX:
				{
					AudioUtils.play(this, BORAX_SOUND, 1,false,null,null,1.2);
					break;
				}
				case SNAKESKIN:
				{
					AudioUtils.play(this, SNAKESKIN_SOUND, 1,false,null,null,1.2);
					break;
				}
				case GUNPOWDER:
				{
					AudioUtils.play(this, GUNPOWDER_SOUND, 1,false,null,null,1.2);
					break;
				}						
				default:
				{
					AudioUtils.play(this, BORAX_SOUND, 1,false,null,null,1.2);
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