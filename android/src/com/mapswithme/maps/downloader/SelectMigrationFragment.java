package com.mapswithme.maps.downloader;

import android.support.v7.widget.RecyclerView;

import com.mapswithme.maps.base.BaseMwmRecyclerFragment;

public class SelectMigrationFragment extends BaseMwmRecyclerFragment
{
  @Override
  protected RecyclerView.Adapter createAdapter()
  {
    // TODO customize download adapter to allow selections
    return new DownloaderAdapter(getRecyclerView(), getActivity());
  }
}