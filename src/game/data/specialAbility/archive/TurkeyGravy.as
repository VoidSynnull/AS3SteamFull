// Status: retired
// Usage (1) ads
// Used by avatar facial ad_pranks_turkey

package game.data.specialAbility.character
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.creators.entity.EmitterCreator;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.CharUtils;
	
	import org.flintparticles.twoD.emitters.Emitter2D;

	public class TurkeyGravy extends SpecialAbility
	{				
		// On activate, load the file passed in as a param
		override public function activate( node:SpecialAbilityNode ):void
		{
			
			//CharUtils.setAnim( node.entity, Salute );
			
			if ( !super.data.isActive )
			{	
				addParticles();				
			}
		}

		override public function deactivate( node:SpecialAbilityNode ):void
		{	
			if(_emitterEntity)
			{
				super.group.removeEntity(_emitterEntity);
				_emitter = null;
				_emitterEntity = null;
			}
		}
		
		private function addParticles():void
		{
			// Check to see which direction the character is facing
			var direction:String = super.entity.get(Spatial).scaleX > 0 ? CharUtils.DIRECTION_LEFT : CharUtils.DIRECTION_RIGHT;
			
			var stringVel:Number = 1;
			
			if (direction == CharUtils.DIRECTION_LEFT)
			{
				stringVel = -1;
			}
			
			// Add the particles
			//_emitter = new SillyString();
			_emitter.init(stringVel);
			var container:DisplayObjectContainer = super.entity.get(Display).container;
			
			// Get the Spatial of the hand and use the X,Y to place our object
			var charspatial:Spatial = super.entity.get(Spatial);
			
			var xPos:Number = charspatial.x + 30;
			var yPos:Number = charspatial.y - 30;
			
			// Flip the object if you're facing Left
			if (direction == CharUtils.DIRECTION_LEFT)
			{
				xPos = charspatial.x - 30;
			}
			_emitterEntity = EmitterCreator.create( group, container, _emitter as Emitter2D, xPos, yPos );
		}
		
		private var _emitter:Object;
		private var _emitterEntity:Entity;
	}
}