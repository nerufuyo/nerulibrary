import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/performance_service.dart';

/// Image loading optimization service
/// 
/// Provides intelligent image caching, compression, and loading
/// optimizations for better app performance and memory usage.
class ImageOptimizer {
  static ImageOptimizer? _instance;
  static ImageOptimizer get instance => _instance ??= ImageOptimizer._();
  
  ImageOptimizer._();
  
  // Image cache configuration
  static const int _maxCacheSize = 100;
  static const int _maxCacheSizeBytes = 50 * 1024 * 1024; // 50MB
  
  // Image compression settings
  static const int _defaultQuality = 85;
  
  /// Initialize image optimizer
  void initialize() {
    _configureImageCache();
    _configureCachedNetworkImage();
  }
  
  /// Configure Flutter's image cache
  void _configureImageCache() {
    PaintingBinding.instance.imageCache.maximumSize = _maxCacheSize;
    PaintingBinding.instance.imageCache.maximumSizeBytes = _maxCacheSizeBytes;
  }
  
  /// Configure cached network image settings
  void _configureCachedNetworkImage() {
    // Configure global cache settings for CachedNetworkImage
    // This would be done in the CachedNetworkImage configuration
  }
  
  /// Create optimized image widget
  Widget createOptimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    String? placeholder,
    ImageSize size = ImageSize.medium,
    bool enableMemoryCache = true,
    bool enableDiskCache = true,
  }) {
    return OptimizedImageWidget(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      size: size,
      enableMemoryCache: enableMemoryCache,
      enableDiskCache: enableDiskCache,
    );
  }
  
  /// Preload images for better performance
  Future<void> preloadImages(
    BuildContext context,
    List<String> imageUrls, {
    ImageSize size = ImageSize.medium,
  }) async {
    PerformanceService.instance.startTiming('image_preload');
    
    try {
      final preloadFutures = imageUrls.map((url) {
        return precacheImage(
          _createImageProvider(url, size),
          context,
        );
      });
      
      await Future.wait(preloadFutures);
      
      PerformanceService.instance.stopTiming('image_preload', metadata: {
        'image_count': imageUrls.length,
        'size': size.name,
        'success': true,
      });
      
    } catch (error) {
      PerformanceService.instance.stopTiming('image_preload', metadata: {
        'image_count': imageUrls.length,
        'size': size.name,
        'error': error.toString(),
        'success': false,
      });
    }
  }
  
  /// Create optimized image provider
  ImageProvider _createImageProvider(String imageUrl, ImageSize size) {
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImageProvider(
        imageUrl,
        cacheKey: '${imageUrl}_${size.name}',
      );
    } else {
      return AssetImage(imageUrl);
    }
  }
  
  /// Compress image bytes
  Future<Uint8List> compressImage(
    Uint8List imageBytes, {
    int quality = _defaultQuality,
    int? maxWidth,
    int? maxHeight,
  }) async {
    PerformanceService.instance.startTiming('image_compression');
    
    try {
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: maxWidth,
        targetHeight: maxHeight,
      );
      
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      final compressedBytes = byteData!.buffer.asUint8List();
      
      PerformanceService.instance.stopTiming('image_compression', metadata: {
        'original_size': imageBytes.length,
        'compressed_size': compressedBytes.length,
        'compression_ratio': (1 - compressedBytes.length / imageBytes.length),
        'quality': quality,
      });
      
      return compressedBytes;
      
    } catch (error) {
      PerformanceService.instance.stopTiming('image_compression', metadata: {
        'error': error.toString(),
      });
      rethrow;
    }
  }
  
  /// Clear image cache
  void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
    
    PerformanceService.instance.recordMetric(PerformanceMetric(
      name: 'image_cache_cleared',
      value: 1,
      unit: 'count',
      timestamp: DateTime.now(),
      metadata: {},
    ));
  }
  
  /// Get image cache statistics
  ImageCacheStatistics getImageCacheStatistics() {
    final cache = PaintingBinding.instance.imageCache;
    
    return ImageCacheStatistics(
      currentSize: cache.currentSize,
      maxSize: cache.maximumSize,
      currentSizeBytes: cache.currentSizeBytes,
      maxSizeBytes: cache.maximumSizeBytes,
      liveImageCount: cache.liveImageCount,
      pendingImageCount: cache.pendingImageCount,
    );
  }
}

/// Optimized image widget with performance monitoring
class OptimizedImageWidget extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? placeholder;
  final ImageSize size;
  final bool enableMemoryCache;
  final bool enableDiskCache;
  
  const OptimizedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.size = ImageSize.medium,
    this.enableMemoryCache = true,
    this.enableDiskCache = true,
  });
  
  @override
  State<OptimizedImageWidget> createState() => _OptimizedImageWidgetState();
}

class _OptimizedImageWidgetState extends State<OptimizedImageWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.startsWith('http')) {
      return _buildNetworkImage();
    } else {
      return _buildAssetImage();
    }
  }
  
  Widget _buildNetworkImage() {
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheKey: '${widget.imageUrl}_${widget.size.name}',
      memCacheWidth: _getCacheWidth(),
      memCacheHeight: _getCacheHeight(),
      
      // Performance optimizations
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
      
      // Placeholder while loading
      placeholder: (context, url) {
        _recordImageEvent('loading');
        return _buildPlaceholder();
      },
      
      // Error widget
      errorWidget: (context, url, error) {
        _recordImageEvent('error', error: error.toString());
        return _buildErrorWidget();
      },
      
      // Success callback
      imageBuilder: (context, imageProvider) {
        _recordImageEvent('loaded');
        return Image(
          image: imageProvider,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        );
      },
    );
  }
  
  Widget _buildAssetImage() {
    return Image.asset(
      widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheWidth: _getCacheWidth(),
      cacheHeight: _getCacheHeight(),
      errorBuilder: (context, error, stackTrace) {
        _recordImageEvent('error', error: error.toString());
        return _buildErrorWidget();
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          _recordImageEvent('loaded');
          return child;
        }
        _recordImageEvent('loading');
        return _buildPlaceholder();
      },
    );
  }
  
  Widget _buildPlaceholder() {
    if (widget.placeholder != null) {
      return Text(widget.placeholder!);
    }
    
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.image,
          color: Colors.grey.shade400,
          size: 32,
        ),
      ),
    );
  }
  
  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.red.shade400,
          size: 32,
        ),
      ),
    );
  }
  
  int? _getCacheWidth() {
    if (widget.width == null) return null;
    return (widget.width! * MediaQuery.of(context).devicePixelRatio).round();
  }
  
  int? _getCacheHeight() {
    if (widget.height == null) return null;
    return (widget.height! * MediaQuery.of(context).devicePixelRatio).round();
  }
  
  void _recordImageEvent(String event, {String? error}) {
    PerformanceService.instance.recordMetric(PerformanceMetric(
      name: 'image_$event',
      value: 1,
      unit: 'count',
      timestamp: DateTime.now(),
      metadata: {
        'url': widget.imageUrl,
        'size': widget.size.name,
        'width': widget.width?.toString() ?? 'auto',
        'height': widget.height?.toString() ?? 'auto',
        if (error != null) 'error': error,
      },
    ));
  }
}

/// Image size presets for optimization
enum ImageSize {
  thumbnail(200),
  small(300),
  medium(500),
  large(800),
  original(0);
  
  const ImageSize(this.maxDimension);
  final int maxDimension;
}

/// Image cache statistics
class ImageCacheStatistics {
  final int currentSize;
  final int maxSize;
  final int currentSizeBytes;
  final int maxSizeBytes;
  final int liveImageCount;
  final int pendingImageCount;
  
  const ImageCacheStatistics({
    required this.currentSize,
    required this.maxSize,
    required this.currentSizeBytes,
    required this.maxSizeBytes,
    required this.liveImageCount,
    required this.pendingImageCount,
  });
  
  double get cacheUsagePercentage => maxSize > 0 ? (currentSize / maxSize) * 100 : 0;
  
  double get memorySizeMB => currentSizeBytes / (1024 * 1024);
  
  double get maxMemorySizeMB => maxSizeBytes / (1024 * 1024);
  
  @override
  String toString() {
    return '''
Image Cache Statistics:
- Images: $currentSize/$maxSize (${cacheUsagePercentage.toStringAsFixed(1)}%)
- Memory: ${memorySizeMB.toStringAsFixed(1)}MB/${maxMemorySizeMB.toStringAsFixed(1)}MB
- Live Images: $liveImageCount
- Pending Images: $pendingImageCount
''';
  }
}
