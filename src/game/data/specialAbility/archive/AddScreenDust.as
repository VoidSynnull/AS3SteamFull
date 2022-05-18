// Status: retired
// Usage (1) ads
// Used by card 2549 (Disney Planes Retardant Powder)

package game.data.specialAbility.character
{
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.group.Scene;
	
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.entity.character.NpcNode;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.specialAbility.DustDrift;
	import game.util.ColorUtil;
	import game.util.SceneUtil;
	
	
	public class AddScreenDust extends SpecialAbility
	{
		override public function activate( node:SpecialAbilityNode ):void
		{
			if ( !super.data.isActive )
			{
				super.setActive(true);
				
				// lock input
				SceneUtil.lockInput(super.group, true);
				dustEmitter = new DustDrift(super.shellApi.viewportWidth, super.shellApi.viewportHeight );
				var box:Rectangle = new Rectangle( -2000, 0, super.shellApi.viewportWidth, super.shellApi.viewportHeight );
				dustEmitter.init();
				_emitterEntity = EmitterCreator.create( super.group, Scene(super.group).overlayContainer, dustEmitter );
				
				// set timer
				SceneUtil.addTimedEvent( super.group, new TimedEvent( 5, 1, startDeactivate));
			}
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			if(startDeath)
			{
				if(_emitterEntity.get(Display).alpha > 0)
					_emitterEntity.get(Display).alpha -= .1;
			}
			if(_emitterEntity.get(Display).alpha <= 0)
			{
				tintChars();
				deactivate(node);
			}
		}
		
		private function startDeactivate():void
		{
			startDeath = true;
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			// unlock controls
			SceneUtil.lockInput( super.group, false );
			
			// remove emitter
			if( _emitterEntity )
			{
				group.removeEntity(_emitterEntity);
			}
			
			super.setActive( false );
		}
		
		private function tintChars():void
		{
			var randomIndex:int;		
			var tintColors:Array = new Array();
			var tintIntensities:Array = new Array();
			
			var numberOfColors:int = 1;
			while ( super.data.params.byId( "tintColor" + numberOfColors) && super.data.params.byId( "tintIntensity" + numberOfColors) )
			{
				tintColors.push(uint( super.data.params.byId( "tintColor" + numberOfColors) ));
				tintIntensities.push(int( super.data.params.byId( "tintIntensity" + numberOfColors) ));
				numberOfColors ++;
			}
			numberOfColors --;
			
			if ( String( super.data.params.byId( "includePlayer" ) ).toLowerCase() == "true" )
			{
				randomIndex = randomInteger(0, numberOfColors - 1);
				ColorUtil.tint(super.entity.get(Display).displayObject, tintColors[randomIndex], tintIntensities[randomIndex]);
			}
			
			
			var nodeList:NodeList = super.group.systemManager.getNodeList( NpcNode );
			for( var nodenpc : NpcNode = nodeList.head; nodenpc; nodenpc = nodenpc.next )
			{
				randomIndex = randomInteger(0, numberOfColors - 1);
				// don't tint npc friends
				if (nodenpc.entity.get(Id).id.substring(0,10) != "npc_friend")
				{
					if(nodenpc.entity.get(Id).id.substring(0,10) != "custom_npc")
						ColorUtil.tint(nodenpc.display.displayObject, tintColors[randomIndex], tintIntensities[randomIndex]);
				}
			}
			
			super.shellApi.specialAbilityManager.removeSpecialAbility(super.shellApi.player, super.data.id);
		}
		
		private function randomInteger(lowNumber:Number, highNumber:Number):Number
		{
			return Math.floor(Math.random() * ( 1 + highNumber - lowNumber)) + lowNumber;
		}
		
		private var _emitterEntity:Entity;
		private var dustEmitter:DustDrift;
		private var startDeath:Boolean = false;
	}
}


