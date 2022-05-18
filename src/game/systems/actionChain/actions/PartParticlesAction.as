// Used by:
// Card 2705 using facial limited_captainunderpants_hat (stink cloud from armpits with FartCloud particle class)
// Card 2707 using item limited_benfranklin_sammich (drip jelly from sandwich with DropExternalAsset particle class)
// Card 3055 using item pclown1 (with ClownWater particle class)
// Card 3056 using item pfirefighter1 (FirefighterExtinguisher particle class)
// Card 3108 using item pfool (with ClownWater part icle class)
// Card 3450 using item stor_fartgun (shoot fart cloud with ShootCloud particle class)
// Used by pack poptropicon_jetpack in bathrooms scene in Con1 (Bubbles particle class)

package game.systems.actionChain.actions
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.creators.entity.EmitterCreator;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.actionChain.ActionCommand;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ExternalImage;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.emitters.Emitter2D;

	// Add particle emitter to avatar part
	// Refer to PaticleEmitterAction for a similar generic class
	// Note: the particles container is placed BEHIND the avatar, so the particles emanate from behind
	public class PartParticlesAction extends ActionCommand
	{
		private var particleClass:Class;
		private var part:String;
		private var startColor:Number;
		private var endColor:Number;
		private var offsetX:Number;
		private var offsetY:Number;
		private var filePath:String;
		private var scale:Number = 0;
		private var inBack:Boolean = false;
		
		private var _id:String;

		/**
		 * Add particle emitter to avatar part (bug: FartCloud particles are sometimes invisible for some reason)
		 * @param particleClass		Particle class
		 * @param part				Part name
		 * @param startColor		Start color
		 * @param endColor			End color
		 * @param offsetX			X offset for particles
		 * @param offsetY			Y offset for particles
		 * @param filePath			Path to external particle swf
		 * @param scale				Scale to apply to particle swf
		*/
		public function PartParticlesAction( particleClass:Class, part:String = CharUtils.HAND_FRONT, startColor:Number = -1, endColor:Number = -1, offsetX:Number = 0, offsetY:Number = 0, filePath:String = "", scale:Number = 0, inBack:Boolean = true ) 
		{
			_id = ClassUtils.getNameByObject(particleClass);
			_id = _id.substr(_id.indexOf("::") + 2);

			this.particleClass = particleClass;
			this.part = part;
			this.startColor = startColor;
			this.endColor = endColor;
			this.offsetX = offsetX;
			this.offsetY = offsetY;
			this.filePath = filePath;
			this.scale = scale;
			this.inBack = inBack;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			if (node == null)
				return;
			
			var npc:Entity = node.entity;
			// Check to see which direction the character is facing
			var direction:String = (npc.get(Spatial).scaleX > 0) ? CharUtils.DIRECTION_LEFT : CharUtils.DIRECTION_RIGHT;
			
			// Add the particles
			var emitter:Object = new particleClass();
			
			var dir:int;
			if(direction == CharUtils.DIRECTION_LEFT)
				dir = -1;
			else
				dir = 1;
			
			// init emitter with direction
			emitter.init(dir);
			
			// add external image
			if ((filePath != "") && (filePath != "none"))
				emitter.addInitializer( new ExternalImage( filePath, true) );
			
			if (scale != 0)
				emitter.addInitializer(new ScaleImageInit( scale, scale ) );

			// init color
			if (startColor != -1)
			{
				if (endColor == -1)
					endColor = startColor;
				emitter.addInitializer( new ColorInit(startColor, endColor));
			}
			
			// this would be the avatar itself
			var npcDisplay:DisplayObject = Display(npc.get(Display)).displayObject;
			
			// create a sprite below the avatar parts layers
			var clip:Sprite = new Sprite();
			
			//Put the particles right behind the character.
			if (inBack)
				npcDisplay.parent.addChildAt(clip, npcDisplay.parent.getChildIndex(npcDisplay));
			else
				npcDisplay.parent.addChild(clip);
			
			// Get the Spatial of the part and use the X,Y to place our object
			var partSpatial:Spatial = CharUtils.getJoint(npc, part).get(Spatial);
			var charspatial:Spatial = npc.get(Spatial);
			
			// xPos is offset in front of avatar
			var xPos:Number = -(partSpatial.x * charspatial.scale) + offsetX;
			var yPos:Number = (partSpatial.y * charspatial.scale) + offsetY;
			
			// NOTE: sometimes the effect doesn't appear when using FartCloud
			EmitterCreator.create( group, clip, emitter as Emitter2D, xPos, yPos, null, _id, charspatial, true, true );
			
			// todo: add delay to wait for emitter to end
			callback();	// once the waitStart timer has completed, execute() is called, and we finish right away.
		}
		
		override public function revert( group:Group ):void
		{
			// remove particles
			var emitterEntity:Entity = group.getEntityById(_id);
			if (emitterEntity)
				group.removeEntity(emitterEntity);
		}
	}
}