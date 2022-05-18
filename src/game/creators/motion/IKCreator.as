package game.creators.motion
{

	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.motion.IKControl;
	import game.components.motion.IKSegment;


	

	public class IKCreator
	{
		public function IKCreator()
		{
			
		}
		
		/**
		 * Create IK using Entities, ideal for rendering IK with a series of chained clips.
		 */
		public function createDisplayIK( group:Group, numSegments:int, segmentSize:Number, assetPath:String, container:DisplayObjectContainer ):Entity
		{
			// create ik control entity
			var ikEntity:Entity = new Entity();
			var ikControl:IKControl = new IKControl();
			ikEntity.add( ikControl );
			
			// create segments, connected to each other via a linked list
			var segmentEntity:Entity;
			var segment:IKSegment;
			var previousSegment:IKSegment;
			for (var i:int = 0; i < numSegments; i++) 
			{
				segmentEntity = new Entity();
				
				segment = new IKSegment();
				segment.size = segmentSize;
				
				if( i == 0 )					//is head
				{
					previousSegment = segment;
					ikControl.head = segment;
				}
				else if ( i != numSegments )	//is standard
				{
					previousSegment.next = segment;
					segment.previous = previousSegment;
				}
				else							// is tail
				{
					previousSegment.next = segment;
					segment.previous = previousSegment;
					ikControl.tail = segment;
					
				}
				previousSegment = segment;
				
				// create and add Spatial
				var spatial:Spatial = new Spatial();
				segmentEntity.add( new Spatial );
				
				// hold referenc eto Spatial within IKSegment (allows for flexibility in system)
				segment.spatial = spatial;
				segmentEntity.add( segment );
				
				// create and add Display, load asset
				var display:Display = new Display();
				display.setContainer( container );
				segmentEntity.add( display );
				group.shellApi.loadFile( assetPath, onAssetLoaded, display );
				
				group.addEntity( segmentEntity );
			}
			
			group.addEntity(ikEntity);
			return ikEntity;
		}
		
		private function onAssetLoaded( asset:DisplayObjectContainer, display:Display ):void
		{
			display.displayObject = asset;
			display.setContainer( display.container );
		}
		
		
		/**
		 * Create IK using points, ideal for rendering IK graphically as opposed to chained clips.
		 */
		public function createPointIK( numSegments:int, segmentLength:Number ):void
		{
			// might want a different control component that doesn't rely on individual entities?

			
		}
	}
}
