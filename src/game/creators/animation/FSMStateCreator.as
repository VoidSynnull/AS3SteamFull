package game.creators.animation
{
	import flash.utils.describeType;
	
	import ash.core.Component;
	import ash.core.Entity;
	import ash.core.Node;
	
	import game.components.Viewport;
	import game.components.animation.FSMControl;
	import game.components.entity.character.animation.AnimationControl;
	import game.nodes.entity.character.CharacterStateNode;
	import game.systems.animation.FSMState;
	import game.systems.entity.character.states.CharacterState;
	import game.util.ClassUtils;
	
	/**
	 * Creates start of a characters.
	 * Creates an entity and assigns data used by the CharacterUpdateSystem to finalize creation.
	 */
	public class FSMStateCreator
	{
		
		public function createState( entity:Entity, stateClass:Class, nodeClass:Class, stateType:String = "") : FSMState
		{
			var fsmControl: FSMControl = entity.get( FSMControl ) as FSMControl;
			if ( fsmControl )
			{
				var fsmState:FSMState = new stateClass();
				
				// create node from entity and add to state
				var node:Node = new nodeClass();
				var variables : XMLList = describeType( nodeClass ).factory.variable;
				for each ( var atom:XML in variables )
				{
					if ( atom.@name != "entity" && atom.@name != "previous" && atom.@name != "next" && atom.@name != "optional" )
					{
						var componentClass : Class = ClassUtils.getClassByName( atom.@type );
						var componentName:String = atom.@name.toString();
						
						node[componentName] = entity.get( componentClass );
						/***************** wrb - reference counting for components ********************/
						if(node[componentName]) { Component(node[componentName]).nodesAddedTo++; }
						/***************** wrb - reference counting for components ********************/
					}
				}
				node.entity = entity;
				fsmState.setNode( node );
				
				// if a type is not specified, check the class
				if( stateType == "" )
				{
					stateType = fsmState.type;
				}
				fsmControl.addState( fsmState, stateType );
				return fsmState;
			}
			return null;
		}
		
		public function createCharacterState( stateClass:Class, character:Entity, stateType:String = "" ) : CharacterState
		{
			var fsmControl: FSMControl = character.get( FSMControl ) as FSMControl;
			if ( fsmControl )
			{
				var state:CharacterState = CharacterState(createState( character, stateClass, CharacterStateNode, stateType)); 
				
				// set viewport
				var viewPort:Viewport = character.get( Viewport );
				viewPort.changed.add( state.setViewport );	// TODO :: handle this
				state.setViewport( viewPort );
				
				// add fsm to main animation entity ( since that is what it will be running )
				var animationControl:AnimationControl = character.get( AnimationControl );
				if(animationControl)
				{
					var primaryAnimEntity:Entity = animationControl.getEntityAt();
					if( !primaryAnimEntity.has( FSMControl ) )
					{
						primaryAnimEntity.add( fsmControl );
					}
				}
				return state;
			}
			return null;
		}
		
		public function createCharacterStateSet( states:Vector.<Class>, character:Entity ) : void
		{
			for (var i:int = 0; i < states.length; i++) 
			{
				createCharacterState( states[i], character, "" );
			}
		}
		
		public function createStateSet( states:Vector.<Class>, entity:Entity, nodeClass:Class ) : void
		{
			for (var i:int = 0; i < states.length; i++) 
			{
				createState( entity, states[i], nodeClass );
			}
		}
	}
}
