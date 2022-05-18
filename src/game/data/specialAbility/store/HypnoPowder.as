// Used by:
// Card 3343 using item store_hypno_powder

package game.data.specialAbility.store
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.creators.entity.EmitterCreator;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Pop;
	import game.data.animation.entity.character.Sword;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.specialAbility.SneezePowder;
	import game.scene.template.CharacterGroup;
	import game.util.CharUtils;
	import game.util.SkinUtils;
	
	import org.flintparticles.twoD.emitters.Emitter2D;

	/**
	 * Hypnotize NPCs with emitter and apply hypno eyes
	 */
	public class HypnoPowder extends SpecialAbility
	{				
		// On activate, load the file passed in as a param
		override public function activate( node:SpecialAbilityNode ):void
		{
			if ( !super.data.isActive )
			{
				_lookData = new LookData();
				var lookAspect:LookAspectData = new LookAspectData( SkinUtils.FACIAL, "mc_hypno_eyes" ); 
				_lookData.applyAspect( lookAspect );
				
				CharUtils.lockControls( node.entity, true, false );
				super.setActive( true );
				CharUtils.setAnim( node.entity, Sword );
				CharUtils.getTimeline( node.entity ).handleLabel("fire", addParticles);
				CharUtils.getTimeline( node.entity ).handleLabel( Animation.LABEL_ENDING, returnControl);
			}
		}	
		
		/**
		 * When reach label in animation 
		 */
		private function addParticles():void
		{
			// scene that holds avatar
			var container:DisplayObjectContainer = super.entity.get(Display).container;
			
			// Get the Spatial of the hand and use the X,Y to place our object
			var handspatial:Spatial = CharUtils.getJoint(super.entity, CharUtils.HAND_FRONT).get(Spatial);
			var charspatial:Spatial = super.entity.get(Spatial);
			
			var xPos:Number = -(handspatial.x * charspatial.scale);
			var yPos:Number = (handspatial.y * charspatial.scale);
			
			// Check to see which direction the character is facing
			var direction:String = super.entity.get(Spatial).scaleX > 0 ? CharUtils.DIRECTION_LEFT : CharUtils.DIRECTION_RIGHT;
			
			// Flip the object if you're facing Left
			if (direction == CharUtils.DIRECTION_LEFT)
				_speedX = -90;
			else
				_speedX = 90;
			// Add the particles
			_emitter = new SneezePowder();
			_emitter.init(_speedX);
			_emitterEntity = EmitterCreator.create( group, container, _emitter as Emitter2D, xPos, yPos, null, "HypnoPowder", charspatial, true, true );
		}
		
		
		/**
		 * When animation ends 
		 * @param character
		 */
		private function returnControl():void
		{
			CharUtils.stateDrivenOn( super.entity );
			CharUtils.lockControls( super.entity, false, false );
			checkNPCProximity( super.entity );
			super.setActive( false );
		}
		
		// If NPCS are in proximity
		private function checkNPCProximity( character:Entity ):void
		{
			var inSceneNpcs:Vector.<Entity> = (character.get(OwningGroup).group.getGroupById('characterGroup') as CharacterGroup).getCharactersInView();
			var spatial:Spatial = character.get(Spatial);
			var offset:Spatial = new Spatial(spatial.x + _speedX * 2, spatial.y)
			
			if(inSceneNpcs)
			{
				for (var i:int = 0; i < inSceneNpcs.length; i++) 
				{
					var distance:Number = getDistance(offset, inSceneNpcs[i].get(Spatial));
					if(distance < 150)
					{
						SkinUtils.applyLook( inSceneNpcs[i], _lookData, false );
						CharUtils.setAnim( inSceneNpcs[i], Pop );
					}
				}
			}
		}
		
		private function getDistance(spatial1:Spatial, spatial2:Spatial):Number
		{	
			return Math.sqrt((spatial1.x - spatial2.x)*(spatial1.x - spatial2.x) + (spatial1.y - spatial2.y)*(spatial1.y - spatial2.y));
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{	
			if(_emitterEntity)
			{
				node.owning.group.removeEntity(_emitterEntity);
				_emitter = null;
				_emitterEntity = null;
			}
		}		
		
		private var _emitter:Object;
		private var _emitterEntity:Entity;
		private var _lookData:LookData;
		private var _holder:Sprite;
		private var _speedX:Number;
		private var _group:Group;
	}
}