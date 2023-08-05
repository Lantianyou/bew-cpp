#ifndef KUIPER_INFER_DATA_BLOB_HPP_
#define KUIPER_INFER_DATA_BLOB_HPP_

#include <cstdint>
#include <xtensor/xarray.hpp>
#include <xtensor/xio.hpp>
#include <xtensor/xview.hpp>

using namespace xt;

template<typename Dtype> class Tensor
{
public:
  explicit Tensor(const uint32_t rows, const uint32_t cols, const uint32_t channels);
  explicit Tensor() = default;

  [[nodiscard]] uint32_t rows() const;
  [[nodiscard]] uint32_t cols() const;
  [[nodiscard]] uint32_t channels() const;
  [[nodiscard]] uint32_t size() const;

  Dtype index(uint32_t offset) const;

private:
  xarray<Dtype> m_data;
};

#endif
