package engine.util
{
    import flash.display.BitmapData;
    import flash.display.BitmapDataChannel;
    import flash.display.BlendMode;
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
	import flash.geom.ColorTransform;
   
    public class CollisionDetection
    {
		/** Get the collision rectangle between two display objects. **/
		public static function getCollisionRect(target1:DisplayObject, target2:DisplayObject, commonParent:DisplayObjectContainer, pixelPrecise:Boolean = false, tolerance:int = 255):Rectangle
		{
			// get bounding boxes in common parent's coordinate space
			var rect1:Rectangle = target1.getBounds(commonParent);
			var rect2:Rectangle = target2.getBounds(commonParent);
		   
			// find the intersection of the two bounding boxes
			var intersectionRect:Rectangle = rect1.intersection(rect2);
		   
			// if not pixel-precise, we're done
			if (!pixelPrecise) return intersectionRect;
		   
			// size of rect needs to be integer size for bitmap data
			intersectionRect.x = Math.floor(intersectionRect.x);
			intersectionRect.y = Math.floor(intersectionRect.y);
			intersectionRect.width = Math.ceil(intersectionRect.width);
			intersectionRect.height = Math.ceil(intersectionRect.height);
		   
			// if the rect is empty, we're done
			if (intersectionRect.isEmpty()) return intersectionRect;
		   
			// calculate the transform for the display object relative to the common parent
			var parentXformInvert:Matrix = commonParent.transform.concatenatedMatrix.clone();
			parentXformInvert.invert();
			var target1Xform:Matrix = target1.transform.concatenatedMatrix.clone();
			target1Xform.concat(parentXformInvert);
			var target2Xform:Matrix = target2.transform.concatenatedMatrix.clone();
			target2Xform.concat(parentXformInvert);
		   
			// translate the target into the rect's space
			target1Xform.translate(-intersectionRect.x, -intersectionRect.y);
			target2Xform.translate(-intersectionRect.x, -intersectionRect.y);
		   
			// combine the display objects
			var bd:BitmapData = new BitmapData(intersectionRect.width, intersectionRect.height, false);
			bd.draw(target1, target1Xform, new ColorTransform(1, 1, 1, 1, 255, -255, -255, tolerance), BlendMode.NORMAL);
			bd.draw(target2, target2Xform, new ColorTransform(1, 1, 1, 1, 255, 255, 255, tolerance), BlendMode.DIFFERENCE);
		   
			// find overlap
			var overlapRect:Rectangle = bd.getColorBoundsRect(0xffffffff, 0xff00ffff);
			overlapRect.offset(intersectionRect.x, intersectionRect.y);
		   
			return overlapRect;
		}
       
        /** Gets the alpha map of the display object and places it in the specified channel. **/
        private static function getAlphaMap(target:DisplayObject, rect:Rectangle, channel:uint, commonParent:DisplayObjectContainer):BitmapData
        {
            // calculate the transform for the display object relative to the common parent
            var parentXformInvert:Matrix = commonParent.transform.concatenatedMatrix.clone();
            parentXformInvert.invert();
            var targetXform:Matrix = target.transform.concatenatedMatrix.clone();
            targetXform.concat(parentXformInvert);
           
            // translate the target into the rect's space
            targetXform.translate(-rect.x, -rect.y);
           
            // draw the target and extract its alpha channel into a color channel
            var bitmapData:BitmapData = new BitmapData(rect.width, rect.height, true, 0);
            bitmapData.draw(target, targetXform);
            var alphaChannel:BitmapData = new BitmapData(rect.width, rect.height, false, 0);
            alphaChannel.copyChannel(bitmapData, bitmapData.rect, new Point(0, 0), BitmapDataChannel.ALPHA, channel);
           
            return alphaChannel;
        }
 
        /** Get the center of the collision's bounding box. **/
        public static function getCollisionPoint(target1:DisplayObject, target2:DisplayObject, commonParent:DisplayObjectContainer, pixelPrecise:Boolean = false, tolerance:Number = 0):Point
        {
            var collisionRect:Rectangle = getCollisionRect(target1, target2, commonParent, pixelPrecise, tolerance);
       
            if (collisionRect != null && collisionRect.size.length> 0)
            {
                var x:Number = (collisionRect.left + collisionRect.right) / 2;
                var y:Number = (collisionRect.top + collisionRect.bottom) / 2;
       
                return new Point(x, y);
            }
       
            return null;
        }
       
        /** Are the two display objects colliding (overlapping)? **/
        public static function isColliding(target1:DisplayObject, target2:DisplayObject, commonParent:DisplayObjectContainer, pixelPrecise:Boolean = false, tolerance:Number = 0):Boolean
        {
            var collisionRect:Rectangle = getCollisionRect(target1, target2, commonParent, pixelPrecise, tolerance);
       
            if (collisionRect != null && collisionRect.size.length> 0) return true;
            else return false;
        }
    }
}