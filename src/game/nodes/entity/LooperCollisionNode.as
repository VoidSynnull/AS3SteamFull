package game.nodes.entity
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.animation.FSMControl;
	import game.components.audio.HitAudio;
	import game.components.entity.character.Player;
	import game.components.hit.CurrentHit;
	import game.components.motion.Edge;
	import game.components.entity.LooperCollider;
	import game.components.entity.MotionMaster;
	
	public class LooperCollisionNode extends Node
	{
		public var collider:LooperCollider;
		public var currentHit:CurrentHit;
		public var display:Display;
		public var edge:Edge;
		public var hitAudio:HitAudio;
		public var id:Id;
		public var motion:Motion;
		public var spatial:Spatial;
		
		public var audio:Audio;
		public var fsmControl:FSMControl;
		public var motionMaster:MotionMaster;
		public var player:Player;
		
		public var optional:Array = [ Audio, FSMControl, MotionMaster, Player ];
	} 
}