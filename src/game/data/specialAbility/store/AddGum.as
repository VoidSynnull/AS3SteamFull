// Used by:
// Card 3114 using ability gum
// Card 3115 using ability gum_cinnamon (CinnamonGum particle class)
// Card 3118  using ability gum_winter (WinterGum particle class and WinterGumTrail particle class)
// Card 3157 using ability gum_spook (SpookGum particle class)
// Card 3182 using ability gum_psycadelic (PsychadelicGum particle class)

package game.data.specialAbility.store 
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.specialAbility.character.BubbleGum;
	import game.creators.entity.EmitterCreator;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.specialAbility.CinnamonGum;
	import game.particles.emitter.specialAbility.ClassicGum;
	import game.particles.emitter.specialAbility.ShamrockGum;
	import game.particles.emitter.specialAbility.SpookGum;
	import game.particles.emitter.specialAbility.WinterGum;
	import game.particles.emitter.specialAbility.WinterGumTrail;
	import game.systems.specialAbility.character.BubbleGumSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SkinUtils;
	
	import org.flintparticles.twoD.emitters.Emitter2D;
	
	/**
	 * Avatar chews gum using BubbleGum system
	 * 
	 * Required params:
	 * swfFath				String		Path to asset
	 * 
	 * Optional params:
	 * particleClass		Class		Particle class (make sure to add class to dynamic manifest) - can be null
	 * trailsClass			Class		Trails class (make sure to add class to dynamic manifest)
	 * particleSwfPath		String		Path to particle swf (TODO: needs to be handled by this class)
	 * as2Mouth				String		Name of AS2 mouth part
	 */
	public class AddGum extends SpecialAbility
	{
		override public function init( node:SpecialAbilityNode ):void
		{
			super.init(node);
			
			// Save the previous mouth part
			prevMouth = SkinUtils.getLookAspect(node.entity, SkinUtils.MOUTH, true).value;
			// set gum mouth as permanent part
			var mouth:String = "gum";
			// override if coming from xml
			if (_as2Mouth != null)
				mouth = _as2Mouth;
			SkinUtils.setSkinPart( node.entity, SkinUtils.MOUTH, mouth, true);
		}
		
		override public function activate( node:SpecialAbilityNode ):void
		{
			// Add the BubbleGum Sytem if it's not there already
			if( !super.group.getSystem( BubbleGumSystem ) )
			{
				bubbleGumSystem = new BubbleGumSystem();
				super.group.addSystem( bubbleGumSystem );
			}
			super.loadAsset(_swfPath, loadComplete);
		}
		
		/**
		 * When swf loaded 
		 * @param clip
		 */
		private function loadComplete(clip:MovieClip):void
		{
			if (clip == null)
				return;
			
			clip.gotoAndStop(1);
			
			var charspatial:Spatial = super.entity.get(Spatial);
			
			// Check to see which direction the character is facing
			var direction:String = super.entity.get(Spatial).scaleX > 0 ? CharUtils.DIRECTION_LEFT : CharUtils.DIRECTION_RIGHT;
			
			var xPos:Number;
			if (direction == CharUtils.DIRECTION_LEFT)
			{
				xPos = charspatial.x - 25;
			} else {
				xPos = charspatial.x + 25;
			}
			var yPos:Number = charspatial.y -25;
			clip.x = xPos;
			clip.y = yPos;
			gumEntity = EntityUtils.createMovingTimelineEntity(entity.group, clip, EntityUtils.getDisplayObject(entity).parent);
			gumEntity.get(Spatial).scaleX = 0;
			gumEntity.get(Spatial).scaleY = 0;
			
			var gum:BubbleGum = new BubbleGum(gumEntity, _particleClass);
			gumEntity.add(gum);
			
			var motion:Motion = gumEntity.get(Motion);
			motion.acceleration = new Point(gum.ax, gum.ay);
			
			// Add trailing particles if they exist
			if(_trailsClass)
			{
				var display:Display = gumEntity.get(Display);
				var spatial:Spatial = gumEntity.get(Spatial);
				var emitter:Object = new _trailsClass();
				emitter.init();
				
				var trailsEmitter:Entity = EmitterCreator.create( gumEntity.group, display.container, emitter as Emitter2D, 0, 0,null, "trail", gumEntity.get(Spatial) );
				gum.trailsEmitter = trailsEmitter;
			}
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			// use default mouth if previous mouth is a gum mouth
			if ((prevMouth != null) && (prevMouth.indexOf("gum") != -1))
				prevMouth = "1";
			SkinUtils.setSkinPart( node.entity, SkinUtils.MOUTH, prevMouth, true );
			SkinUtils.saveLook(node.entity);
		}
		
		public var required:Array = ["swfPath"];
		
		public var _swfPath:String;
		public var _particleClass:Class;
		public var _particleFilePath:String;
		public var _trailsClass:Class;
		public var _as2Mouth:String;
		
		private var prevMouth:*;
		private var gumEntity:Entity;
		private var bubbleGumSystem:BubbleGumSystem;
		
		private var classicGumParticles:ClassicGum;
		private var cinnamonGumParticles:CinnamonGum;
		private var winterGumParticles:WinterGum;
		private var spookGumParticles:SpookGum;
		private var shamrockGum:ShamrockGum;
		private var particles:WinterGumTrail;
	}
}