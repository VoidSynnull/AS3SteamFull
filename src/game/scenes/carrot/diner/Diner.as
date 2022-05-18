package game.scenes.carrot.diner
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.character.part.SkinPart;
	import game.components.render.Reflection;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Drink;
	import game.scenes.carrot.CarrotEvents;
	import game.data.sound.SoundModifier;
	import game.scene.template.AudioGroup;
	import game.scene.template.PlatformerGameScene;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Ring;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class Diner extends PlatformerGameScene
	{
		private var missingPoster:MissingPoster;
//		private var drinkMixer:DrinkMixer;
		private var _events:CarrotEvents;
		
		public function Diner()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carrot/diner/";
			
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
			_events = super.events as CarrotEvents;
			
			bubblesInSoda();
			
			//These characters need a reflection show they show up on the floor.
			this.player.add(new Reflection());
			this.getEntityById("waitress").add(new Reflection());
			this.getEntityById("char1").add(new Reflection());
			//This character is event-driven, so a check to see if null is needed.
			var char3:Entity = this.getEntityById("char3");
			if(char3) char3.add(new Reflection());
			
			SceneInteraction(super.getEntityById("interaction1").get(SceneInteraction)).reached.add(sceneInteractionTriggered);
			SceneInteraction(super.getEntityById("interaction2").get(SceneInteraction)).reached.add(sceneInteractionTriggered);
		}
		
		private function sceneInteractionTriggered(character:Entity, interaction:Entity):void
		{
			if(Id(interaction.get(Id)).id == "interaction1")
			{
				missingPoster = super.addChildGroup(new MissingPoster(super.overlayContainer)) as MissingPoster;
			}
			else if(Id(interaction.get(Id)).id == "interaction2")
			{
				MotionUtils.zeroMotion( player );
				
				var drinkMixer:DrinkMixer = super.addChildGroup(new DrinkMixer(super.overlayContainer)) as DrinkMixer;
				drinkMixer.sendDrink.add( handleDrink );
			}
		}
		
		private function bubblesInSoda():void
		{
			var soda:Entity;
			var audioGroup:AudioGroup;
			for ( var i:int = 1; i <=5; i ++ )
			{
				var emitter:Emitter2D = new Emitter2D();
			
				emitter.counter = new Steady(10);
				
				emitter.addInitializer( new ImageClass( Ring, [1, 2], true ) );
				emitter.addInitializer( new Position( new LineZone( new Point( -24, 0 ), new Point( 24, 0 ) ) ) );
				emitter.addInitializer( new Velocity( new PointZone( new Point( 0, -25 ) ) ) );
				emitter.addInitializer( new ScaleImageInit( .5, 1) );
				emitter.addInitializer( new ColorInit(0x66FFFFFF, 0x66FFFFFF) );
				emitter.addInitializer( new Lifetime( .55 ) );
				
				emitter.addAction( new Age() );
				emitter.addAction( new Move() );
				emitter.addAction( new Accelerate(0, -25));
				
				soda = EntityUtils.createSpatialEntity( this, super._hitContainer[ "s" + i ]);
				soda.add( new Id( "soda" + i ));
				audioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
				audioGroup.addAudioToEntity( soda );
				
				EmitterCreator.create( this, EntityUtils.getDisplayObject( soda ), emitter );
			}
		}
		
		private function handleDrink(newHairColor:uint):void
		{
			CharUtils.setAnim(player, Drink);	//item gets set by animation
			SkinUtils.setSkinPart(player, SkinUtils.ITEM, "glass");
			
			CharUtils.setPartColor( super.player, CharUtils.ITEM, newHairColor, "default"); //Won't work without default
			Timeline(CharUtils.getTimeline(player)).handleLabel("setColor", Command.create( setHairColor, newHairColor ));
			Timeline(CharUtils.getTimeline(player)).handleLabel("ending", removeGlass );
			SceneUtil.addTimedEvent( this, new TimedEvent( .9, 1, drink));
		}
		
		private function drink():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "drink_soda_01.mp3", 1, false, [SoundModifier.EFFECTS]);
		}
		
		private function setHairColor(newHairColor:uint):void
		{
			SkinUtils.setSkinPart( player, SkinUtils.HAIR_COLOR, newHairColor, true );
			super.shellApi.saveLook();	//save look change
		}
		
		private function removeGlass():void
		{
			var skinPart:SkinPart = SkinUtils.getSkinPart( player, SkinUtils.ITEM )
			skinPart.remove();
		}
	}
}