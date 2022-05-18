package game.scenes.mocktropica.cheeseInterior.nodes {

	import ash.core.Node;
	
	import engine.components.Display;

	import game.scenes.mocktropica.cheeseInterior.components.CheeseMachine;
	import game.components.entity.VariableTimeline;
	
	public class CheeseMachineNode extends Node {

		public var timeline:VariableTimeline;
		public var machine:CheeseMachine;

		public var display:Display;

	} // End CheeseAssemblyNode

} // End package