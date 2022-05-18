package game.scenes.shrink.schoolInterior
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.sound.SoundModifier;
	import game.scene.template.PlatformerGameScene;
	import game.util.EntityUtils;
	
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class SchoolInterior extends PlatformerGameScene
	{
		public function SchoolInterior()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/shrink/schoolInterior/";
			
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
			
			setUpFountains();
		}
		
		private function setUpFountains():void
		{
			var audioRange:AudioRange;
			var clip:MovieClip;
			var deathZone:DeathZone = new DeathZone( new RectangleZone( 2500, 440, 3400, 500 ));
			var display:Display;
			var fountain:Entity;
			var fountainEmitter:SprayEmitter;
			var number:int;
			var sceneInteraction:SceneInteraction;
			var sprayEntity:Entity;
			
			for( number = 1; number < 3; number ++)
			{
				clip = _hitContainer[ "fountainButton" + number ];
				
				fountainEmitter = new SprayEmitter();
				fountainEmitter.init( 10, .925, -Math.PI * 3 / 4, 500, 1000, 0xc8d7e1, 0xb0c3cc, deathZone );//, -100, 100, 100 )));// -1500, 5 * number, 0, 20 * number )));
				sprayEntity = EmitterCreator.create( this, _hitContainer, fountainEmitter, clip.x + 20, clip.y - 40, null, "spray" + number, null, false );
				display = sprayEntity.get( Display );
				display.moveToBack();
				
				fountain = EntityUtils.createSpatialEntity( this, clip, _hitContainer );
				audioRange = new AudioRange( 1000, 0, 1, Quad.easeIn );
				fountain.add( new Audio()).add(new Id( "fountain" + number )).add( audioRange );
				
				fountain.add(new SceneInteraction());
				display = fountain.get( Display );
				
				InteractionCreator.addToEntity( fountain, [ InteractionCreator.CLICK ]);
				sceneInteraction = fountain.get( SceneInteraction );
				sceneInteraction.reached.add( Command.create( sprayFountain, sprayEntity.get( Emitter )));
				
				ToolTipCreator.addToEntity( fountain );
			}
		}
		
		public function sprayFountain(player:Entity, fountain:Entity, emitter:Emitter):void
		{
			if(emitter.emitter.counter.running)
			{
				Audio(fountain.get(Audio)).stop("effects/water_fountain_01_L.mp3","effects");
				emitter.emitter.counter.stop();
			}
			else
			{
				Audio(fountain.get(Audio)).play("effects/water_fountain_01_L.mp3",true,SoundModifier.POSITION);
				emitter.start = true;
				emitter.emitter.counter.resume();
			}
		}
	}
}