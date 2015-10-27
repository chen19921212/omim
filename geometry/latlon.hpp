#pragma once

#include "base/math.hpp"

#include "std/string.hpp"

namespace ms
{

/// \brief Class for representing WGS point.
class LatLon
{
public:
  double lat, lon;

  LatLon(double lat, double lon) : lat(lat), lon(lon) {}

  static LatLon Zero() { return LatLon(0., 0.); }

  bool operator == (ms::LatLon const & p) const
  {
    return lat == p.lat && lon == p.lon;
  }

  bool EqualDxDy(LatLon const & p, double eps) const
  {
    return ((fabs(lat - p.lat) < eps) && (fabs(lon - p.lon) < eps));
  }

  struct Hash
  {
    size_t operator()(ms::LatLon const & p) const
    {
      return my::Hash(p.lat, p.lon);
    }
  };
};

string DebugPrint(LatLon const & t);

}  // namespace ms
