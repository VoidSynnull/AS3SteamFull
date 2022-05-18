// Used by:
// Card 3325 using item vh_sneezing_powder

package game.data.specialAbility.store
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.creators.entity.EmitterCreator;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.PointItem;
	import game.data.animation.entity.character.Sneeze;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.specialAbility.SneezePowder;
	import game.scene.template.CharacterGroup;
	import game.util.CharUtils;
	
	import org.flintparticles.twoD.emitters.Emitter2D;

	/**
	 * Release particles that make NPCs sneeze 
	 */
	public class SneezingPowder extends SpecialAbility
	{				
		// On activate, load the file passed in as a param
		override public function activate( node:SpecialAbilityNode ):void
		{	
			if ( !super.data.isActive )
			{
				CharUtils.lockControls( node.entity, true, false );
				//CharUtils.stateDrivenOff( node.entity );
				super.setActive( true );
				CharUtils.setAnim( node.entity, PointItem );
				CharUtils.getTimeline( node.entity ).handleLabel("pointing", addParticles);
				CharUtils.getTimeline( node.entity ).handleLabel( Animation.LABEL_ENDING, startSneezeAnim);
			}
		}	
		
		
		/**
		 * Add particles when label reached 
		 */
		private function addParticles():void
		{
			// Add the particles
			_emitter = new SneezePowder();
			_emitter.init();
			var container:DisplayObjectContainer = super.entity.get(Display).container;
			
			// Get the Spatial of the hand and use the X,Y to place our object
			var handspatial:Spatial = CharUtils.getJoint(super.entity, CharUtils.HAND_FRONT).get(Spatial);
			var charspatial:Spatial = super.entity.get(Spatial);
			
			var xPos:Number = -(handspatial.x * charspatial.scale);
			var yPos:Number = (handspatial.y * charspatial.scale);
			
			_emitterEntity = EmitterCreator.create( group, container, _emitter as Emitter2D, xPos, yPos, null, "SneezingPowder", charspatial, true, true );
		}
		
		private function startSneezeAnim():void
		{	
			CharUtils.stateDrivenOn( super.entity );
			CharUtils.lockControls( super.entity, false, false );
			CharUtils.setAnim( super.entity, Sneeze, false );
			super.setActive( false );
			checkNPCProximity();
		}
		
		/**
		 * If NPCS are in proximity, then make them sneeze too
		 */
		private function checkNPCProximity():void
		{
			var inSceneNpcs:Vector.<Entity> = (super.group.getGroupById('characterGroup') as CharacterGroup).getCharactersInView();
			
			if(inSceneNpcs)
			{
				for (var i:int = 0; i < inSceneNpcs.length; i++) 
				{
					var distance:Number = getDistance(super.entity.get(Spatial), inSceneNpcs[i].get(Spatial));
					if(distance < 200)
					{
						CharUtils.setAnim( inSceneNpcs[i], Sneeze );
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
				super.group.removeEntity(_emitterEntity);
				_emitter = null;
				_emitterEntity = null;
			}
		}
		
		private var _emitter:Object;
		private var _emitterEntity:Entity;
	}
}