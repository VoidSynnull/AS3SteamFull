package game.systems
{
	public class SystemPriorities
	{
		public static const preUpdate : int 				= 1;
		public static const update : int 					= 2;
		public static const postUpdate : int 				= 3;
		public static const timelineControl : int 			= 4;
		public static const timelineEvent : int 			= 5;
		public static const animate : int 					= 6;
		public static const moveControl : int 				= 7;
		public static const inputComplete : int 		    = 8;
		
		public static const move : int 						= 10;
		public static const resetColliderFlags : int        = 11;
		public static const resolveCollisions : int 		= 12;
		public static const resolveParentCollisions : int 	= 13;
		public static const checkCollisions : int 		    = 14;
		public static const moveComplete : int 				= 15;
		
		public static const cameraZoomUpdate : int 			= 16;
		public static const cameraUpdate : int 				= 17;
		
		public static const updateAnim : int 				= 25;
		public static const sequenceAnim : int 				= 36;
		public static const checkAnimActive : int 			= 47;
		public static const autoAnim : int 					= 58;
		public static const loadAnim : int 					= 69;
		public static const updateSound : int 				= 70;
		public static const spatialOffset : int 			= 80;
		public static const preRender : int 				= 81;
		public static const render : int 					= 92;
		public static const postRender : int 				= 93;
		public static const sceneInteraction : int  		= 103;
		public static const lowest : int 					= 114;	
	}
}
