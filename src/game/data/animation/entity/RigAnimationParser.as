package game.data.animation.entity
{
	import fl.motion.Motion;
	
	import game.util.DataUtils;
	
	
	/**
	 * 
	 */
	public class RigAnimationParser
	{		
		public function parse( xml:XML ):RigAnimationData
		{
			var root : XML = xml as XML;
			// General info about animation
			var animation:RigAnimationData = new RigAnimationData();
			animation.name 				= DataUtils.getString(root.attribute("name"));
			animation.noEnd 			= DataUtils.getBoolean(root.attribute("noEnd"));
			var motionList : XMLList 	= root.parts.children() as XMLList;	
			animation.duration 			= DataUtils.useNumber(motionList[0].attribute("duration"), 0);
			
			// parse frame data
			animation.frames = TimelineParser.parseXML( XML(root.events), animation.duration )
			
			// Parse animation data
			var partAnimData : PartAnimationData;
			var motion : Motion;
			
			for (var n:uint=0; n<motionList.length(); n++)		// for each Part in the animation...
			{	
				partAnimData = new PartAnimationData();			//...create a DataPartAnimation
				
				motion = new Motion(motionList[n]);
				partAnimData.motion = motion;

				partAnimData.name = DataUtils.getString(motionList[n].child(0).child(0).@instanceName) ;
				partAnimData.x = DataUtils.useNumber(motionList[n].child(0).child(0).@x, 0);
				partAnimData.y = DataUtils.useNumber(motionList[n].child(0).child(0).@y, 0);
				partAnimData.rotation = DataUtils.useNumber(motionList[n].child(0).child(0).@rotation, 0);
				partAnimData.xScale = DataUtils.useNumber(motionList[n].child(0).child(0).@scaleX, 1);
				partAnimData.yScale = DataUtils.useNumber(motionList[n].child(0).child(0).@scaleY, 1);
				partAnimData.transformPoint = motion.source.transformationPoint;
				partAnimData.dimensions = motion.source.dimensions;
								
				partAnimData.createOffsets(); // offsets x & y positions to account for transformation point;

				// add AnimationPartData to DataAnimation
				animation.addPart( partAnimData );	
			}
			
			return animation;
		}
	}
}